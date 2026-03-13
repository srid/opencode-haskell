{- |
Module      : OpenCode.Types
Description : Types for OpenCode server API
Copyright   : (c) 2026 Sridhar Ratnakumar
License     : MIT
Maintainer  : srid@srid.ca
Stability   : experimental

This module provides the data types used by the OpenCode server API.
All types derive 'FromJSON' and 'ToJSON' for serialization.
-}
module OpenCode.Types (
  -- * IDs
  SessionID (..),
  MessageID (..),
  ProjectID (..),
  ProviderID (..),
  PartID (..),
  WorkspaceID (..),
  ModelID (..),

  -- * Core types
  Health (..),
  Session (..),
  SessionTime (..),
  SessionSummary (..),
  Message (..),
  UserMessage (..),
  AssistantMessage (..),
  TextPart (..),
  TextPartInput (..),
  textPartInput,
  Part (..),
  MessageInput (..),
  MessageResponse (..),
  SessionCreateInput (..),
  Project (..),
  Config (..),
  Provider (..),
  ProvidersResponse (..),
)
where

import Data.Aeson (FromJSON (..), FromJSONKey, Options (..), ToJSON (..), ToJSONKey, Value, defaultOptions, genericParseJSON, genericToJSON, withObject, (.:), (.:?))
import Data.Map.Strict qualified as Map
import Web.HttpApiData (FromHttpApiData (..), ToHttpApiData (..))

jsonOptions :: Options
jsonOptions = defaultOptions {fieldLabelModifier = Prelude.id}

-- | A session identifier (e.g., @ses_xxx@).
newtype SessionID = SessionID {unSessionID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, ToHttpApiData, FromHttpApiData, FromJSON, ToJSON)

-- | A message identifier (e.g., @msg_xxx@).
newtype MessageID = MessageID {unMessageID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON)

-- | A project identifier.
newtype ProjectID = ProjectID {unProjectID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON)

-- | A provider identifier (e.g., @openai@, @anthropic@).
newtype ProviderID = ProviderID {unProviderID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON, FromJSONKey, ToJSONKey)

-- | A part identifier.
newtype PartID = PartID {unPartID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON)

-- | A workspace identifier.
newtype WorkspaceID = WorkspaceID {unWorkspaceID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON)

-- | A model identifier (e.g., @litellm/glm-latest@, @openai/gpt-4@).
newtype ModelID = ModelID {unModelID :: Text}
  deriving stock (Show, Eq, Generic)
  deriving newtype (IsString, Ord, ToString, ToText, FromJSON, ToJSON)

-- | Server health status.
data Health = Health
  { healthy :: Bool
  , version :: Text
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON Health where
  parseJSON = genericParseJSON jsonOptions
instance ToJSON Health where
  toJSON = genericToJSON jsonOptions

-- | Timestamps for a session or message.
data SessionTime = SessionTime
  { created :: Int
  -- ^ Creation timestamp (milliseconds since epoch).
  , updated :: Maybe Int
  -- ^ Last update timestamp.
  , completed :: Maybe Int
  -- ^ Completion timestamp (for messages).
  , compacting :: Maybe Int
  -- ^ Compacting timestamp.
  , archived :: Maybe Int
  -- ^ Archival timestamp.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON SessionTime where
  parseJSON = withObject "SessionTime" $ \v ->
    SessionTime
      <$> v .: "created"
      <*> v .:? "updated"
      <*> v .:? "completed"
      <*> v .:? "compacting"
      <*> v .:? "archived"
instance ToJSON SessionTime where
  toJSON = genericToJSON jsonOptions

-- | Summary of changes in a session.
data SessionSummary = SessionSummary
  { additions :: Int
  -- ^ Number of lines added.
  , deletions :: Int
  -- ^ Number of lines deleted.
  , files :: Int
  -- ^ Number of files modified.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON SessionSummary where
  parseJSON = genericParseJSON jsonOptions
instance ToJSON SessionSummary where
  toJSON = genericToJSON jsonOptions

-- | An OpenCode session.
data Session = Session
  { id :: SessionID
  -- ^ Unique session identifier.
  , slug :: Text
  -- ^ URL-friendly slug.
  , projectID :: ProjectID
  -- ^ ID of the project this session belongs to.
  , workspaceID :: Maybe WorkspaceID
  -- ^ Optional workspace ID.
  , directory :: FilePath
  -- ^ Working directory for the session.
  , parentID :: Maybe SessionID
  -- ^ Parent session ID (for forked sessions).
  , title :: Text
  -- ^ Session title.
  , version :: Text
  -- ^ Session version.
  , time :: SessionTime
  -- ^ Timestamps.
  , summary :: Maybe SessionSummary
  -- ^ Optional summary of changes.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON Session where
  parseJSON = withObject "Session" $ \v ->
    Session
      <$> v .: "id"
      <*> v .: "slug"
      <*> v .: "projectID"
      <*> v .:? "workspaceID"
      <*> v .: "directory"
      <*> v .:? "parentID"
      <*> v .: "title"
      <*> v .: "version"
      <*> v .: "time"
      <*> v .:? "summary"
instance ToJSON Session where
  toJSON = genericToJSON jsonOptions

-- | A text part in a message (from the server).
data TextPart = TextPart
  { id :: Maybe PartID
  -- ^ Optional part ID.
  , text :: Text
  -- ^ The text content.
  , partType :: Maybe Text
  -- ^ The type of part (e.g., @\"text\"@, @\"reasoning\"@).
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON TextPart where
  parseJSON = withObject "TextPart" $ \v ->
    TextPart
      <$> v .:? "id"
      <*> v .: "text"
      <*> v .:? "type"
instance ToJSON TextPart where
  toJSON = genericToJSON jsonOptions {fieldLabelModifier = \case "partType" -> "type"; x -> x}

{- | Input for creating a text part when sending a message.

Use 'textPartInput' to create a text part:

>>> textPartInput "Hello, world!"
TextPartInput {partType = "text", text = "Hello, world!"}
-}
data TextPartInput = TextPartInput
  { partType :: Text
  -- ^ The type of part (should be @\"text\"@).
  , text :: Text
  -- ^ The text content.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON TextPartInput where
  parseJSON = genericParseJSON jsonOptions {fieldLabelModifier = \case "partType" -> "type"; x -> x}
instance ToJSON TextPartInput where
  toJSON = genericToJSON jsonOptions {fieldLabelModifier = \case "partType" -> "type"; x -> x}

{- | Create a text part input for sending a message.

>>> textPartInput "What is 2+2?"
TextPartInput {partType = "text", text = "What is 2+2?"}
-}
textPartInput :: Text -> TextPartInput
textPartInput = TextPartInput "text"

-- | A part of a message (text or other type).
data Part
  = -- | A text part.
    PartText TextPart
  | -- | Some other JSON value (e.g., step-start, step-finish).
    PartOther Value
  deriving stock (Show, Eq, Generic)

instance FromJSON Part where
  parseJSON v =
    withObject
      "Part"
      ( \obj -> do
          partType <- obj .:? "type"
          case partType of
            Just ("text" :: Text) -> PartText <$> parseJSON v
            Just "reasoning" -> PartText <$> parseJSON v
            _ -> pure $ PartOther v
      )
      v
instance ToJSON Part where
  toJSON (PartText p) = toJSON p
  toJSON (PartOther v) = v

-- | A message from the user.
data UserMessage = UserMessage
  { id :: MessageID
  -- ^ Message ID.
  , sessionID :: SessionID
  -- ^ Session ID.
  , parts :: [Part]
  -- ^ Message parts.
  , time :: SessionTime
  -- ^ Timestamps.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON UserMessage where
  parseJSON = withObject "UserMessage" $ \v ->
    UserMessage
      <$> v .: "id"
      <*> v .: "sessionID"
      <*> v .: "parts"
      <*> v .: "time"
instance ToJSON UserMessage where
  toJSON = genericToJSON jsonOptions

-- | A message from the assistant.
data AssistantMessage = AssistantMessage
  { id :: MessageID
  -- ^ Message ID.
  , sessionID :: SessionID
  -- ^ Session ID.
  , time :: Maybe SessionTime
  -- ^ Optional timestamps.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON AssistantMessage where
  parseJSON = withObject "AssistantMessage" $ \v ->
    AssistantMessage
      <$> v .: "id"
      <*> v .: "sessionID"
      <*> v .:? "time"
instance ToJSON AssistantMessage where
  toJSON = genericToJSON jsonOptions

-- | A message (either from user or assistant).
data Message
  = MsgUser UserMessage
  | MsgAssistant AssistantMessage
  deriving stock (Show, Eq, Generic)

instance FromJSON Message where
  parseJSON v = (MsgUser <$> parseJSON v) <|> (MsgAssistant <$> parseJSON v)
instance ToJSON Message where
  toJSON (MsgUser m) = toJSON m
  toJSON (MsgAssistant m) = toJSON m

{- | Input for sending a message.

>>> MessageInput [textPartInput "Hello!"]
MessageInput {parts = [TextPartInput {partType = "text", text = "Hello!"}]}
-}
newtype MessageInput = MessageInput
  { parts :: [TextPartInput]
  -- ^ The parts of the message.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON MessageInput where
  parseJSON = genericParseJSON jsonOptions
instance ToJSON MessageInput where
  toJSON = genericToJSON jsonOptions

-- | Response from sending a message.
data MessageResponse = MessageResponse
  { info :: AssistantMessage
  -- ^ Information about the assistant message.
  , parts :: [Part]
  -- ^ The response parts (text, reasoning, etc.).
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON MessageResponse where
  parseJSON = genericParseJSON jsonOptions
instance ToJSON MessageResponse where
  toJSON = genericToJSON jsonOptions

{- | Input for creating a session.

>>> SessionCreateInput (Just "My Session") Nothing
SessionCreateInput {title = Just "My Session", parentID = Nothing}
-}
data SessionCreateInput = SessionCreateInput
  { title :: Maybe Text
  -- ^ Optional session title.
  , parentID :: Maybe SessionID
  -- ^ Optional parent session ID (for forking).
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON SessionCreateInput where
  parseJSON = withObject "SessionCreateInput" $ \v ->
    SessionCreateInput
      <$> v .:? "title"
      <*> v .:? "parentID"
instance ToJSON SessionCreateInput where
  toJSON = genericToJSON jsonOptions {omitNothingFields = True}

-- | An OpenCode project.
data Project = Project
  { id :: ProjectID
  -- ^ Project ID.
  , worktree :: FilePath
  -- ^ Path to the worktree.
  , vcs :: Maybe Text
  -- ^ Version control system (e.g., @\"git\"@).
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON Project where
  parseJSON = withObject "Project" $ \v ->
    Project
      <$> v .: "id"
      <*> v .: "worktree"
      <*> v .:? "vcs"
instance ToJSON Project where
  toJSON = genericToJSON jsonOptions

-- | Server configuration.
newtype Config = Config
  { model :: Maybe ModelID
  -- ^ The configured model ID.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON Config where
  parseJSON = genericParseJSON jsonOptions
instance ToJSON Config where
  toJSON = genericToJSON jsonOptions

-- | An AI provider.
data Provider = Provider
  { id :: ProviderID
  -- ^ Provider ID (e.g., @openai@, @anthropic@).
  , name :: Text
  -- ^ Human-readable name.
  , source :: Maybe Text
  -- ^ Source type (e.g., @\"custom\"@).
  , env :: Maybe [Text]
  -- ^ Required environment variables.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON Provider where
  parseJSON = withObject "Provider" $ \v ->
    Provider
      <$> v .: "id"
      <*> v .: "name"
      <*> v .:? "source"
      <*> v .:? "env"
instance ToJSON Provider where
  toJSON = genericToJSON jsonOptions

-- | Response from listing providers.
data ProvidersResponse = ProvidersResponse
  { allProviders :: [Provider]
  -- ^ All available providers.
  , connected :: Maybe [ProviderID]
  -- ^ IDs of connected providers.
  , defaultModel :: Maybe (Map.Map ProviderID ModelID)
  -- ^ Default model per provider.
  }
  deriving stock (Show, Eq, Generic)

instance FromJSON ProvidersResponse where
  parseJSON = withObject "ProvidersResponse" $ \v ->
    ProvidersResponse
      <$> v .: "all"
      <*> v .:? "connected"
      <*> v .:? "default"
instance ToJSON ProvidersResponse where
  toJSON = genericToJSON jsonOptions
