{
  pkgs,
  boards,
  ...
}: {
  imports = [boards.luckfox-pico-plus.module];

  networking.hostName = "sbc-flasher";
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  networking.interfaces.eth0 = {
    address = "192.168.10.100/24";
    gateway = "192.168.10.1";
  };

  environment.systemPackages = [
    pkgs.pkgsStatic.curl
    (pkgs.pkgsStatic.htop.override { sensorsSupport = false; })
  ];

  devShell.serialDevices = {
    "debug-uart" = {
      baud = 115200;
      symlink = "/dev/ttyS2";
      echo = true;
    };
  };

  devShell.usbDevices = {
    "console" = {
      type = "serial";
      symlink = "/dev/ttyACM0";
    };
    "mass0" = {
      type = "storage";
      storageSize = 128;
      storageFs = "vfat";
      symlink = "/dev/usbdisk0";
    };
  };
}
