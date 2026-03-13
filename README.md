# opencode-haskell

[![Hackage](https://img.shields.io/hackage/v/opencode.svg)](https://hackage.haskell.org/package/opencode)

Haskell client library for [OpenCode](https://github.com/anomalyco/opencode) server API.

## Usage

```haskell
import OpenCode

main :: IO ()
main = do
  client <- mkClient "localhost" 4096
  
  -- Check health
  Right health <- getHealth client
  
  -- Create session and send message
  Right session <- createSession client Nothing (SessionCreateInput (Just "My Session") Nothing)
  Right response <- sendMessage client session.id Nothing (MessageInput [textPartInput "Hello!"])
  
  -- Clean up
  deleteSession client session.id Nothing
```

## Run example

```bash
just example
```

Or with custom server:

```bash
nix run .#example -- localhost:4096
```
