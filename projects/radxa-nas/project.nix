{ pkgs, boards, ... }:

{
  imports = [ boards.radxa-cm5 ];

  networking.hostName = "radxa-nas";

  networking.interfaces.eth0 = {
    useDHCP = true;
  };

  environment.systemPackages = [ pkgs.curl ];
}