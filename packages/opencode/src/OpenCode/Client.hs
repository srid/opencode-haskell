{-|
Module      : OpenCode.Client
Description : HTTP client for OpenCode server API
Copyright   : (c) 2026 Sridhar Ratnakumar
License     : MIT
Maintainer  : srid@srid.ca
Stability   : experimental

This module provides the HTTP client for interacting with the OpenCode server.
-}
module OpenCode.Client
  ( OpenCodeClient(..)
  , mkClient
  )
where

import Network.HTTP.Client (defaultManagerSettings, newManager)
import Servant.API (Get, JSON, Post, Delete, ReqBody, Capture, QueryParam, type (:>), (:<|>)(..))
import Servant.Client (BaseUrl(..), ClientEnv, ClientError, client, mkClientEnv, runClientM, Scheme(..))

import OpenCode.Types

type HealthAPI = "global" :> "health" :> Get '[JSON] Health

type SessionListAPI = "session" :> QueryParam "directory" Text :> Get '[JSON] [Session]

type SessionCreateAPI = "session" :> QueryParam "directory" Text :> ReqBody '[JSON] SessionCreateInput :> Post '[JSON] Session

type SessionGetAPI = "session" :> Capture "sessionID" SessionID :> QueryParam "directory" Text :> Get '[JSON] Session

type SessionDeleteAPI = "session" :> Capture "sessionID" SessionID :> QueryParam "directory" Text :> Delete '[JSON] Bool

type MessageAPI = "session" :> Capture "sessionID" SessionID :> "message" :> QueryParam "directory" Text :> ReqBody '[JSON] MessageInput :> Post '[JSON] MessageResponse

type ProjectListAPI = "project" :> Get '[JSON] [Project]

type ProjectCurrentAPI = "project" :> "current" :> Get '[JSON] Project

type ConfigAPI = "config" :> Get '[JSON] Config

type ProviderAPI = "provider" :> Get '[JSON] ProvidersResponse

type OpenCodeAPI =
  HealthAPI
  :<|> SessionListAPI
  :<|> SessionCreateAPI
  :<|> SessionGetAPI
  :<|> SessionDeleteAPI
  :<|> MessageAPI
  :<|> ProjectListAPI
  :<|> ProjectCurrentAPI
  :<|> ConfigAPI
  :<|> ProviderAPI

apiProxy :: Proxy OpenCodeAPI
apiProxy = Proxy

-- | A client for interacting with the OpenCode server API.
--
-- Create a client using 'mkClient', then use the record fields to make API calls.
--
-- >>> client <- mkClient "localhost" 4096
-- >>> getHealth client
-- Right (Health {healthy = True})
data OpenCodeClient = OpenCodeClient
  { getHealth :: IO (Either ClientError Health)
    -- ^ Check if the server is healthy. Calls @GET \/global\/health@.
  , listSessions :: Maybe Text -> IO (Either ClientError [Session])
    -- ^ List all sessions. Optionally filter by directory.
    -- Calls @GET \/session?directory=...@.
  , createSession :: Maybe Text -> SessionCreateInput -> IO (Either ClientError Session)
    -- ^ Create a new session. Optionally specify directory.
    -- Calls @POST \/session@.
  , getSession :: SessionID -> Maybe Text -> IO (Either ClientError Session)
    -- ^ Get a session by ID. Calls @GET \/session\/{sessionID}@.
  , deleteSession :: SessionID -> Maybe Text -> IO (Either ClientError Bool)
    -- ^ Delete a session by ID. Calls @DELETE \/session\/{sessionID}@.
  , sendMessage :: SessionID -> Maybe Text -> MessageInput -> IO (Either ClientError MessageResponse)
    -- ^ Send a message to a session. Calls @POST \/session\/{sessionID}\/message@.
    --
    -- >>> sendMessage client "ses_xxx" Nothing (MessageInput [textPartInput "Hello"])
    -- Right (MessageResponse {...})
  , listProjects :: IO (Either ClientError [Project])
    -- ^ List all projects. Calls @GET \/project@.
  , getCurrentProject :: IO (Either ClientError Project)
    -- ^ Get the current project. Calls @GET \/project\/current@.
  , getConfig :: IO (Either ClientError Config)
    -- ^ Get the server configuration. Calls @GET \/config@.
  , listProviders :: IO (Either ClientError ProvidersResponse)
    -- ^ List all AI providers. Calls @GET \/provider@.
  , clientEnv :: ClientEnv
    -- ^ The underlying servant client environment (for advanced usage).
  }

-- | Create a new OpenCode client.
--
-- >>> client <- mkClient "localhost" 4096
-- >>> getHealth client
-- Right (Health {healthy = True})
--
-- The client uses HTTP (not HTTPS). For HTTPS, you would need to modify
-- the client to use 'tlsManagerSettings' and 'Https' scheme.
mkClient :: Text -> Int -> IO OpenCodeClient
mkClient host port = do
  manager <- newManager defaultManagerSettings
  let baseUrl = BaseUrl Http (toString host) port ""
      env = mkClientEnv manager baseUrl
      ( healthH
        :<|> sessionListH
        :<|> sessionCreateH
        :<|> sessionGetH
        :<|> sessionDeleteH
        :<|> messageH
        :<|> projectListH
        :<|> projectCurrentH
        :<|> configH
        :<|> providerH
        ) = client apiProxy
  pure OpenCodeClient
    { getHealth = runClientM healthH env
    , listSessions = \dir -> runClientM (sessionListH dir) env
    , createSession = \dir input -> runClientM (sessionCreateH dir input) env
    , getSession = \sid dir -> runClientM (sessionGetH sid dir) env
    , deleteSession = \sid dir -> runClientM (sessionDeleteH sid dir) env
    , sendMessage = \sid dir input -> runClientM (messageH sid dir input) env
    , listProjects = runClientM projectListH env
    , getCurrentProject = runClientM projectCurrentH env
    , getConfig = runClientM configH env
    , listProviders = runClientM providerH env
    , clientEnv = env
    }
