{ lib, ... }:

let
  inherit (lib) mkOption mkEnableOption types;

  interfaceOpts = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        default = "192.168.1.100/24";
        description = "IP address with CIDR prefix to assign to the interface.";
      };

      gateway = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default gateway to add when this interface is created.";
      };

      mac = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "MAC address to assign. If null, a random one is used.";
      };
    };
  };

in {
  options.devShell = {
    networkInterfaces = mkOption {
      type = types.attrsOf interfaceOpts;
      default = {};
      description = ''
        Fake network interfaces to create in the devshell.
        Keys are interface names (e.g. "eth0").
        Interfaces are created as dummy devices inside a network namespace.
      '';
      example = {
        "eth0" = { address = "192.168.1.100/24"; gateway = "192.168.1.1"; };
      };
    };
  };
}