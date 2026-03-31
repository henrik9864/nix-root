{ lib, ... }:

let
  inherit (lib) mkOption mkEnableOption types;

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
        description = "Symlink path pointing to the PTY slave.";
      };

      echo = mkOption {
        type = types.bool;
        default = false;
        description = "If true, the fake serial device echoes back everything written to it.";
      };

      logFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If set, all data written to the PTY master side is tee'd to this file.";
      };
    };
  };

  usbDeviceOpts = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "serial" "storage" "custom" ];
        default = "serial";
        description = "Type of USB gadget to emulate.";
      };

      symlink = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Symlink path for the device.";
      };

      storageSize = mkOption {
        type = types.int;
        default = 64;
        description = "Size of the backing file in MiB (storage type only).";
      };

      storageFs = mkOption {
        type = types.enum [ "vfat" "ext4" ];
        default = "vfat";
        description = "Filesystem type for the storage image.";
      };

      setupScript = mkOption {
        type = types.lines;
        default = "";
        description = "Arbitrary shell script for 'custom' type.";
      };
    };
  };

in {
  options.devShell = {
    serialDevices = mkOption {
      type = types.attrsOf serialDeviceOpts;
      default = {};
      description = "Fake serial devices to create in the devshell.";
    };

    usbDevices = mkOption {
      type = types.attrsOf usbDeviceOpts;
      default = {};
      description = "Fake USB devices to create in the devshell.";
    };
  };
}