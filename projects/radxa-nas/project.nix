{ pkgs, boards, ... }:

{
  imports = [ boards.radxa-cm5 ];

  rootfs.extraPackages = [ pkgs.curl ];

  rootfs.files = {
    "/etc/hostname" = { text = "radxa-nas"; };
  };
}