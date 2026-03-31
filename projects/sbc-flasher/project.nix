{ pkgs, boards, ... }:

{
  imports = [ boards.luckfox-pico-plus ];

  rootfs.extraPackages = [ pkgs.curl ];

  rootfs.files = {
    "/etc/hostname" = { text = "sbc-flasher"; };
  };

  devShell.networkInterfaces = {
    "eth1" = {
      address = "192.168.1.100/24";
      gateway = "192.168.1.1";
    };
  };

  devShell.serialDevices = {
    "debug-uart" = {
      baud    = 1500000;
      symlink = "/dev/ttyS2";
      echo    = true;
    };
  };

  devShell.usbDevices = {
    "console" = {
      type    = "serial";
      symlink = "/dev/ttyACM0";
    };
    "mass0" = {
      type        = "storage";
      storageSize = 128;
      storageFs   = "vfat";
      symlink     = "/dev/usbdisk0";
    };
  };
}