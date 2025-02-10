{
  description = "StevenBlack blocklist reformatted for Unbound";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      confName = "blocklist.conf";
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.stdenv.mkDerivation
            {
              name = "stevenblack-unbound";
              version = "unstable-2025-02-04";
              src = pkgs.fetchFromGitHub
                {
                  owner = "StevenBlack";
                  repo = "hosts";
                  rev = "04e625de9df0cce5264767c0e8524b5dcaaaf02c";
                  sha256 = "1aygfbm46pa1lz055r7vq9lgdniqmybxhca854xkp0w0fb9k8jac";
                };

              sourceRoot = ".";

              installPhase = ''
                cat source/hosts | awk '/^0\.0\.0\.0/ { if ( $2 !~ /0\.0\.0\.0/ ) { print "local-zone: \""$2".\" always_null" }}' > blocklist.conf
                mkdir -p $out
                cp blocklist.conf $out/${confName}
              '';
            };
        }
      ) //
    {
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          pkg = self.packages.${pkgs.system}.default;
          cfg = config.services.unbound.blocklist;
        in
        {
          options.services.unbound.blocklist = {
            enable = mkEnableOption "Enables DNS blocklist generated from StevenBlack hosts file";
          };

          config = mkIf cfg.enable {
            services.unbound.settings.server = {
              include = "${pkg}/${confName}";
            };
          };
        };
    };
}
