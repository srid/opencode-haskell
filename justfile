default:
    @just --list

# Run hoogle
docs:
    echo http://127.0.0.1:8888
    hoogle serve -p 8888 --local

# Run cabal repl
repl *ARGS:
    cabal repl {{ ARGS }}

# Run ghcid -- auto-recompile and run `main` function
run:
    ghcid -T :main

# Run the example against the OpenCode server (uses tailscale IP by default)
example *ARGS:
    nix run .#example -- $(tailscale ip -4):4096 {{ ARGS }}
