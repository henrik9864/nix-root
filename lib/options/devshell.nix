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

  serialDeviceOpts = types.submodule {
    options = {
      baud = mkOption {
        type = types.int;
        default = 115200;
        description = "Baud rate to configure on the fake serial device.";
      };

      symlink = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          If set, create a symlink at this path pointing to the PTY slave.
          For example "/dev/ttyUSB0".
          The symlink is created relative to the rootfs workdir.
        '';
      };

      echo = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If true, the fake serial device echoes back everything written to it.
          Useful for basic loopback testing.
        '';
      };

      logFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          If set, all data written to the PTY master side is tee'd to this file.
          The path is relative to the rootfs workdir.
        '';
      };
    };
  };

  usbDeviceOpts = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "serial" "storage" "custom" ];
        default = "serial";
        description = ''
          Type of USB gadget to emulate:
          - "serial"  – creates a PTY pair and a symlink, emulating a USB-serial adapter (e.g. /dev/ttyACM0).
          - "storage" – creates a backing file and a symlink, emulating a USB mass-storage device.
          - "custom"  – runs the user-supplied `setupScript` verbatim.
        '';
      };

      symlink = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Device symlink path to create inside the rootfs workdir.
          Defaults depend on type: /dev/ttyACM0 for serial, /dev/usbdisk0 for storage.
        '';
      };

      storageSize = mkOption {
        type = types.int;
        default = 64;
        description = "Size in MiB of the backing file for USB mass-storage emulation.";
      };

      storageFs = mkOption {
        type = types.enum [ "vfat" "ext4" ];
        default = "vfat";
        description = "Filesystem to create on the USB mass-storage backing file.";
      };

      setupScript = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Custom shell commands to run for this USB device.
          Only used when type is "custom".
          Available variables: ROOTFS, DEVSHELL_TMPDIR.
        '';
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

    serialDevices = mkOption {
      type = types.attrsOf serialDeviceOpts;
      default = {};
      description = ''
        Fake serial devices to create in the devshell via PTY pairs (using socat).
        Keys are logical names (e.g. "serial0", "debug-uart").
        Each entry creates a socat PTY pair; the slave path is exported as
        SERIAL_<NAME> and optionally symlinked into the rootfs workdir.
      '';
      example = {
        "debug-uart" = {
          baud = 1500000;
          symlink = "/dev/ttyS2";
          echo = true;
        };
      };
    };

    usbDevices = mkOption {
      type = types.attrsOf usbDeviceOpts;
      default = {};
      description = ''
        Fake USB devices to create in the devshell.
        Keys are logical names (e.g. "console", "mass0").
        - "serial"  type creates a PTY pair acting as a USB-serial adapter.
        - "storage" type creates a loopback-backed block-device file.
        - "custom"  type runs an arbitrary setup script.
      '';
      example = {
        "console" = { type = "serial"; symlink = "/dev/ttyACM0"; };
        "mass0"   = { type = "storage"; storageSize = 128; storageFs = "vfat"; symlink = "/dev/usbdisk0"; };
      };
    };
  };
}