{-|
Module      : OpenCode
Description : Haskell client library for OpenCode server API
Copyright   : (c) 2026 Sridhar Ratnakumar
License     : MIT
Maintainer  : srid@srid.ca
Stability   : experimental

This library provides a type-safe Haskell client for the OpenCode server API.
It uses servant-client for type-safe HTTP requests.

==== Basic Usage

@
import OpenCode

main :: IO ()
main = do
  client <- mkClient "localhost" 4096
  
  -- Check server health
  health <- getHealth client
  print health
  
  -- Create a session and send a message
  session <- createSession client Nothing (SessionCreateInput Nothing Nothing)
  response <- sendMessage client session.id Nothing (MessageInput [textPartInput "Hello!"])
  print response
@
-}
module OpenCode
  ( module OpenCode.Types
  , module OpenCode.Client
  )
where

import OpenCode.Client
import OpenCode.Types
