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
              version = "unstable-2024-05-12";
              src = pkgs.fetchFromGitHub
                {
                  owner = "StevenBlack";
                  repo = "hosts";
                  rev = "dac298c4ae897b3e2607b41952d8b3a0449ca2ef";
                  sha256 = "0rl6pirpdkdic55gqp20837hf66s95pd2ifys7ihpjgym9d3yhwj";
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
