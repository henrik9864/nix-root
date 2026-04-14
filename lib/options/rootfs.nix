{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;

  fileOpts = types.submodule {
    options = {
      text = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Text content of the file. Mutually exclusive with 'source'.";
      };

      source = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a source file. Mutually exclusive with 'text'.";
      };

      mode = mkOption {
        type = types.str;
        default = "0644";
        description = "File permissions (octal string).";
      };
    };
  };

  interfaceOpts = types.submodule {
    options = {
      address = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Static IP address with CIDR prefix (e.g. 192.168.1.100/24).";
      };

      gateway = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default gateway for this interface.";
      };

      useDHCP = mkOption {
        type = types.bool;
        default = false;
        description = "Use DHCP on this interface.";
      };

      mac = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "MAC address to assign. Used by devshell for dummy interfaces.";
      };
    };
  };

  userOpts = types.submodule {
    options = {
      uid = mkOption {
        type = types.int;
        description = "User ID.";
      };

      group = mkOption {
        type = types.str;
        default = "nogroup";
        description = "Primary group name.";
      };

      home = mkOption {
        type = types.str;
        default = "/var/empty";
        description = "Home directory.";
      };

      shell = mkOption {
        type = types.str;
        default = "/bin/sh";
        description = "Login shell.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "User description (GECOS field).";
      };
    };
  };
in {
  options = {
    networking = {
      hostName = mkOption {
        type = types.str;
        default = "nixroot";
        description = "System hostname.";
      };

      nameservers = mkOption {
        type = types.listOf types.str;
        default = ["1.1.1.1"];
        description = "DNS nameservers.";
      };

      interfaces = mkOption {
        type = types.attrsOf interfaceOpts;
        default = {};
        description = "Network interface configuration. Used by both rootfs init and devshell.";
      };
    };

    users.users = mkOption {
      type = types.attrsOf userOpts;
      default = {
        root = {
          uid = 0;
          group = "root";
          home = "/root";
          shell = "/bin/sh";
          description = "root";
        };
      };
      description = "User accounts.";
    };

    users.groups = mkOption {
      type = types.attrsOf (types.submodule {
        options.gid = mkOption {
          type = types.int;
          description = "Group ID.";
        };
      });
      default = {
        root = {gid = 0;};
      };
      description = "Group definitions.";
    };

    environment.etc = mkOption {
      type = types.attrsOf fileOpts;
      default = {};
      description = ''
        Files to place in /etc. Keys are paths relative to /etc.
      '';
    };

    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Packages to install into the rootfs.";
    };

    boot.initScript = mkOption {
      type = types.lines;
      default = ''
        #!/bin/sh
        mount -t proc  none /proc
        mount -t sysfs none /sys
        mount -t devtmpfs none /dev 2>/dev/null || mdev -s

        echo ":: Boot OK ::"
        exec /bin/sh
      '';
      description = "Contents of /init in the rootfs.";
    };

    rootfs = {
      overlay = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a directory overlaid on the rootfs.";
      };

      extraCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands run inside the rootfs derivation.";
      };
    };
  };
}
