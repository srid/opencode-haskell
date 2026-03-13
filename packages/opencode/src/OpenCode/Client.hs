{- |
Module      : OpenCode.Client
Description : HTTP client for OpenCode server API
Copyright   : (c) 2026 Sridhar Ratnakumar
License     : MIT
Maintainer  : srid@srid.ca
Stability   : experimental

This module provides the HTTP client for interacting with the OpenCode server.
-}
module OpenCode.Client (
  OpenCodeClient (..),
  mkClient,
)
where

import Network.HTTP.Client (defaultManagerSettings, newManager)
import Servant.API (Capture, Delete, Get, JSON, Post, QueryParam, ReqBody, (:<|>) (..), type (:>))
import Servant.Client (BaseUrl (..), ClientEnv, ClientError, Scheme (..), client, mkClientEnv, runClientM)

import OpenCode.Types

-- | Health check endpoint.
type HealthAPI = "global" :> "health" :> Get '[JSON] Health

-- | Sub-routes for a specific session ID.
type SessionMemberAPI =
  Get '[JSON] Session
    :<|> Delete '[JSON] Bool
    :<|> "message" :> QueryParam "directory" FilePath :> ReqBody '[JSON] MessageInput :> Post '[JSON] MessageResponse

-- | Grouped Session routes.
type SessionAPI =
  QueryParam "directory" FilePath :> Get '[JSON] [Session]
    :<|> QueryParam "directory" FilePath :> ReqBody '[JSON] SessionCreateInput :> Post '[JSON] Session
    :<|> Capture "sessionID" SessionID :> QueryParam "directory" FilePath :> SessionMemberAPI

-- | Grouped Project routes.
type ProjectAPI =
  Get '[JSON] [Project]
    :<|> "current" :> Get '[JSON] Project

-- | Server configuration endpoint.
type ConfigAPI = "config" :> Get '[JSON] Config

-- | Provider listing endpoint.
type ProviderAPI = "provider" :> Get '[JSON] ProvidersResponse

-- | Combined OpenCode API.
type OpenCodeAPI =
  HealthAPI
    :<|> "session" :> SessionAPI
    :<|> "project" :> ProjectAPI
    :<|> ConfigAPI
    :<|> ProviderAPI

apiProxy :: Proxy OpenCodeAPI
apiProxy = Proxy

{- | A client for interacting with the OpenCode server API.

Create a client using 'mkClient', then use the record fields to make API calls.

>>> client <- mkClient "localhost" 4096
>>> getHealth client
Right (Health {healthy = True})
-}
data OpenCodeClient = OpenCodeClient
  { getHealth :: IO (Either ClientError Health)
  -- ^ Check if the server is healthy. Calls @GET \/global\/health@.
  , listSessions :: Maybe FilePath -> IO (Either ClientError [Session])
  {- ^ List all sessions.

  The @FilePath@ argument filters by working directory context.
  Pass 'Nothing' to list all sessions regardless of directory.
  -}
  , createSession :: Maybe FilePath -> SessionCreateInput -> IO (Either ClientError Session)
  {- ^ Create a new session.

  The @FilePath@ argument sets the working directory context for the session.
  This determines which project/files the LLM will operate on.
  Pass 'Nothing' to use the server's current directory.
  -}
  , getSession :: SessionID -> Maybe FilePath -> IO (Either ClientError Session)
  -- ^ Get a session by ID. The @FilePath@ is the working directory context.
  , deleteSession :: SessionID -> Maybe FilePath -> IO (Either ClientError Bool)
  -- ^ Delete a session by ID. The @FilePath@ is the working directory context.
  , sendMessage :: SessionID -> Maybe FilePath -> MessageInput -> IO (Either ClientError MessageResponse)
  {- ^ Send a message to a session.

  The @FilePath@ argument is the working directory context for the request.
  Pass 'Nothing' to use the session's existing directory.
  -}
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

{- | Create a new OpenCode client.

>>> client <- mkClient "localhost" 4096
>>> getHealth client
Right (Health {healthy = True})

The client uses HTTP (not HTTPS). For HTTPS, you would need to modify
the client to use 'tlsManagerSettings' and 'Https' scheme.
-}
mkClient :: Text -> Int -> IO OpenCodeClient
mkClient host port = do
  manager <- newManager defaultManagerSettings
  let baseUrl = BaseUrl Http (toString host) port ""
      env = mkClientEnv manager baseUrl
      ( healthH
          :<|> ( sessionListH
                   :<|> sessionCreateH
                   :<|> sessionMemberH
                 )
          :<|> ( projectListH
                   :<|> projectCurrentH
                 )
          :<|> configH
          :<|> providerH
        ) = client apiProxy
  pure
    OpenCodeClient
      { getHealth = runClientM healthH env
      , listSessions = \dir -> runClientM (sessionListH dir) env
      , createSession = \dir input -> runClientM (sessionCreateH dir input) env
      , getSession = \sid dir ->
          let (getH :<|> _ :<|> _) = sessionMemberH sid dir
           in runClientM getH env
      , deleteSession = \sid dir ->
          let (_ :<|> deleteH :<|> _) = sessionMemberH sid dir
           in runClientM deleteH env
      , sendMessage = \sid dir input ->
          let (_ :<|> _ :<|> msgH) = sessionMemberH sid dir
           in runClientM (msgH dir input) env
      , listProjects = runClientM projectListH env
      , getCurrentProject = runClientM projectCurrentH env
      , getConfig = runClientM configH env
      , listProviders = runClientM providerH env
      , clientEnv = env
      }
