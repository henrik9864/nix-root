{ lib, ... }:

let
  inherit (lib) mkOption types;
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
  };
}