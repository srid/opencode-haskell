module Main where

import Data.Map.Strict qualified as Map
import Main.Utf8 qualified as Utf8
import OpenCode

onError :: (Show e) => Either e a -> IO a
onError = either (fail . show) pure

main :: IO ()
main = Utf8.withUtf8 $ do
  putTextLn "OpenCode Haskell Client Example"
  putTextLn "================================"

  args <- getArgs
  let serverAddr = case args of
        [addr] -> toText addr
        _ -> "localhost:4096"

  let (host, portStr) = case break (== ':') (toString serverAddr) of
        (h, ':' : p) -> (toText h, p)
        (h, _) -> (toText h, "4096")
      port = fromMaybe 4096 (readMaybe portStr)

  putTextLn $ "Connecting to OpenCode server at " <> host <> ":" <> show port
  c <- mkClient host port

  putTextLn "\n--- Health Check ---"
  health <- onError =<< getHealth c
  putTextLn $ "Server health: " <> show health

  putTextLn "\n--- Config ---"
  cfg <- onError =<< getConfig c
  putTextLn $ "Model: " <> show cfg.model

  putTextLn "\n--- Providers ---"
  providers <- onError =<< listProviders c
  putTextLn $ "Total providers: " <> show (length providers.allProviders)
  putTextLn "Connected providers:"
  case providers.connected of
    Nothing -> putTextLn "  (none)"
    Just conns -> forM_ conns $ \pid ->
      putTextLn $ "  " <> toText pid

  putTextLn "\n--- Projects ---"
  projects <- onError =<< listProjects c
  putTextLn $ "Found " <> show (length projects) <> " projects:"
  forM_ projects $ \p ->
    putTextLn $ "  " <> toText (p.id) <> " -> " <> toText p.worktree

  putTextLn "\n--- Current Project ---"
  currentProj <- onError =<< getCurrentProject c
  putTextLn $ "Current: " <> toText (currentProj.id) <> " at " <> toText currentProj.worktree

  putTextLn "\n--- Sessions by Project ---"
  sessions <- onError =<< listSessions c Nothing
  let byProject = Map.fromListWith (++) [(s.projectID, [s]) | s <- sessions]

  if Map.null byProject
    then putTextLn "No sessions found."
    else forM_ (Map.toList byProject) $ \(pid, sess) -> do
      putTextLn $ "\n[" <> toText pid <> "]"
      forM_ sess $ \s ->
        putTextLn $ "  " <> toText (s.id) <> " - " <> s.title

  putTextLn "\n--- Create Session & Send Message ---"
  session <- onError =<< createSession c Nothing (SessionCreateInput (Just "Haskell client example") Nothing)
  putTextLn $ "Created session: " <> toText (session.id)

  putTextLn "\n--- Get Session ---"
  session' <- onError =<< getSession c (session.id) Nothing
  putTextLn $ "Session title: " <> session'.title

  putTextLn "\n--- Send Message ---"
  putTextLn "Sending: 'What is 2+2? Answer briefly.'"
  response <- onError =<< sendMessage c (session.id) Nothing (MessageInput [textPartInput "What is 2+2? Answer briefly."])
  putTextLn "Response:"
  forM_ response.parts $ \case
    PartText tp -> putTextLn $ "  " <> tp.text
    PartOther _ -> pass

  putTextLn "\n--- Delete Session ---"
  deleted <- onError =<< deleteSession c (session.id) Nothing
  putTextLn $ "Deleted session: " <> toText (session.id) <> " (" <> show deleted <> ")"

  putTextLn "\nDone!"
