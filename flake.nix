{
  description = "StevenBlack blocklist reformatted for Unbound";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let
      confName = "blacklist.conf";
    in
    flake-utils.lib.eachSystem flake-utils.lib.allSystems
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.stdenv.mkDerivation
            {
              name = "stevenblack-unbound";
              version = "2023-10-20";
              src = pkgs.fetchFromGitHub
                {
                  owner = "StevenBlack";
                  repo = "hosts";
                  rev = "master";
                  hash = "sha256-fPMGNj1dXrbxJDxiC8U41NLz1vL5m3Ayw8uC1HJm4sU=";
                };

              sourceRoot = ".";

              installPhase = ''
                grep '^0\.0\.0\.0' source/hosts | awk '{print "local-zone: \""$2"\" always_null"}' > blacklist.conf
                mkdir -p $out
                cp blacklist.conf $out/${confName}
              '';
            };
        }
      ) //
    {
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          pkg = self.packages.${pkgs.system}.default;
          cfg = config.services.unbound.blacklist;
        in
        {
          options.services.unbound.blacklist = {
            enable = mkEnableOption "Enables DNS blacklist generated from StevenBlack hosts file";
          };

          config = mkIf cfg.enable {
            services.unbound.settings = {
              include = "${pkg}/${confName}";
            };
          };
        };
    };
}
