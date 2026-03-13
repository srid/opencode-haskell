# Agent Notes

## Changelog

All PRs must update the CHANGELOG.md file with a description of changes under the appropriate version section.

## Version

All PRs must increment the version in `packages/opencode/opencode.cabal` appropriately.

## Example

The example in `packages/example/src/Main.hs` must demonstrate ALL API endpoints provided by the library. Run it with:

```bash
nix run .#example -- "host:port"
```

When adding new API endpoints, update the example accordingly.

## Type Accuracy

Types in `OpenCode.Types` must match the actual JSON from the OpenCode server API. If parsing fails, check the actual API response with curl and update types accordingly.
