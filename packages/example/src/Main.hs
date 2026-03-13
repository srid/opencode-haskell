module Main where

import Main.Utf8 qualified as Utf8
import OpenCode

main :: IO ()
main = Utf8.withUtf8 $ do
  putTextLn "OpenCode Haskell Client Example"
  putTextLn "================================"
  
  args <- getArgs
  let serverAddr = case args of
        [addr] -> toText addr
        _ -> "localhost:4096"
  
  let (host, portStr) = case break (== ':') (toString serverAddr) of
        (h, ':':p) -> (toText h, p)
        (h, _) -> (toText h, "4096")
      port = fromMaybe 4096 (readMaybe portStr)
  
  putTextLn $ "Connecting to OpenCode server at " <> host <> ":" <> show port
  c <- mkClient host port
  
  putTextLn "\n--- Health Check ---"
  healthResult <- getHealth c
  case healthResult of
    Left err -> fail $ "Health check failed: " <> show err
    Right health -> putTextLn $ "Server health: " <> show health
  
  putTextLn "\n--- Sending a prompt to the LLM ---"
  putTextLn "Creating a new session..."
  sessionResult <- createSession c Nothing (SessionCreateInput (Just "Haskell client test") Nothing)
  session <- case sessionResult of
    Left err -> fail $ "Failed to create session: " <> show err
    Right s -> pure s
  
  putTextLn $ "Created session: " <> unSessionID session.id
  putTextLn "Sending prompt: 'What is 2+2? Answer briefly.'"
  msgResult <- sendMessage c session.id Nothing (MessageInput [textPartInput "What is 2+2? Answer briefly."])
  response <- case msgResult of
    Left err -> fail $ "Failed to send message: " <> show err
    Right r -> pure r
  
  putTextLn "Response received:"
  forM_ response.parts $ \part -> case part of
    PartText tp -> putTextLn $ "  " <> tp.text
    PartOther _ -> pure ()
  
  putTextLn "\n--- Cleaning up ---"
  putTextLn $ "Deleting session: " <> unSessionID session.id
  deleteResult <- deleteSession c session.id Nothing
  case deleteResult of
    Left err -> putTextLn $ "Warning: Failed to delete session: " <> show err
    Right True -> putTextLn "Session deleted successfully"
    Right False -> putTextLn "Session deletion returned false"
  
  putTextLn "\nDone!"
