{ pkgs, ... }:

{
  imports = [ ../../boards/radxa-cm5/board.nix ];

  rootfs.extraPackages = [ pkgs.curl ];

  rootfs.files = {
    "/etc/hostname" = { text = "radxa-nas"; };
  };
}