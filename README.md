# DNS Blocklists for Unbound

The amazing [StevenBlack](https://github.com/StevenBlack/hosts) repo has block lists for various domains that have been known to serve ads and other malicious content.

However the blocklist is in `/etc/hosts` format that looks like this:

```shell
0.0.0.0 ck.getcookiestxt.com
0.0.0.0 eu1.clevertap-prod.com
0.0.0.0 wizhumpgyros.com
0.0.0.0 coccyxwickimp.com
0.0.0.0 webmail-who-int.000webhostapp.com
```

And if you want to use it with Unbound, you need to have it in a format like this:

```shell
local-zone: "ck.getcookiestxt.com." always_null
local-zone: "eu1.clevertap-prod.com." always_null
local-zone: "wizhumpgyros.com." always_null
local-zone: "coccyxwickimp.com." always_null
local-zone: "webmail-who-int.000webhostapp.com." always_null
```

So what this Nix flake does is convert the above format to the below format. Then it exposes the converted file as a package. It additionally exposes a NixOS Module that can be used to automatically configure Unbound to use this converted blocklist.

```nix
{
  description = "NixOS configuration with Unbound Blocklist";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    blocklist.url = "github:mirosval/unbound-blocklist";
  };

  outputs = inputs@{ nixpkgs, blocklist, ... }: {
    nixosConfigurations = {
      hostName = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          blocklist.nixosModules.default
          {
            services.unbound = {
                enable = true;
                # This line enables the blocklist
                blocklist.enable = true;
            };
          }
        ];
      };
    };
  };
}
```

What it exactly does is it adds an `include` statement to the `server` block of the `/etc/unbound/unbound.conf` file and points it to the `blocklist.conf` file generated by the package included in this flake.

## TODO

There are some ways this could be extended:

- [ ] Add the other optional lists from StevenBlack (rn it's just the ads + malware)
- [ ] Add CI so that the blocklists are automatically updated

## Updating

In order to reflect the latest changes to the upstream blocklists, take the following steps:

```shell
# Get the hash of the latest master
nix shell nixpkgs#nurl --command nurl https://github.com/StevenBlack/hosts master
> fetchFromGitHub {
  owner = "StevenBlack";
  repo = "hosts";
  rev = "master";
  hash = "sha256-fPMGNj1dXrbxJDxiC8U41NLz1vL5m3Ayw8uC1HJm4sU="; # <-- this
}

# Update it in flake.nix
```
