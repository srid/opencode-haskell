{ root, inputs, ... }:
{
  imports = [
    inputs.haskell-flake.flakeModule
  ];
  perSystem = { self', lib, config, pkgs, ... }: {
    haskellProjects.default = {
      projectRoot = lib.fileset.toSource {
        inherit root;
        fileset = lib.fileset.unions [
          (root + /packages)
          (root + /cabal.project)
          (root + /LICENSE)
          (root + /README.md)
        ];
      };

      packages = { };

      settings = {
        opencode = {
          stan = true;
        };
      };

      autoWire = [ "packages" "apps" "checks" ];
    };

    packages.default = self'.packages.opencode;
    apps.default = self'.apps.opencode-example;
    apps.example = self'.apps.opencode-example;
  };
}
