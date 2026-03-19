{ lib, ... }:

let
  inherit (lib) mkOption types;

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

in {
  options.rootfs = {
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to install into the rootfs.";
    };

    extraCommands = mkOption {
      type = types.lines;
      default = "";
      description = "Extra shell commands run inside the rootfs derivation.";
    };

    initScript = mkOption {
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

    passwd = mkOption {
      type = types.str;
      default = "root:x:0:0:root:/root:/bin/sh";
      description = "Contents of /etc/passwd.";
    };

    group = mkOption {
      type = types.str;
      default = "root:x:0:";
      description = "Contents of /etc/group.";
    };

    resolv = mkOption {
      type = types.str;
      default = "nameserver 1.1.1.1";
      description = "Contents of /etc/resolv.conf.";
    };

    overlay = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a directory whose contents are copied on top of the rootfs.
        Mirrors the rootfs layout (e.g. overlay/etc/hostname → /etc/hostname).
      '';
    };

    files = mkOption {
      type = types.attrsOf fileOpts;
      default = {};
      description = ''
        Declarative file definitions. Keys are absolute paths in the rootfs.
        Each value has 'text' or 'source', and an optional 'mode'.
        These are applied after the overlay, so they take priority.
      '';
      example = {
        "/etc/hostname" = { text = "my-board"; };
        "/etc/myapp.conf" = { source = ./files/myapp.conf; mode = "0600"; };
      };
    };
  };
}