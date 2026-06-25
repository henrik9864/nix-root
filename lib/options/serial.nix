{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.serial = {
    console = mkOption {
      type = types.str;
      default = "ttyS2,1500000";
      description = "Kernel serial console argument.";
    };

    earlycon = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Earlycon argument value (e.g. uart8250,mmio32,0xff4c0000,115200). Added as earlycon=<value> if set.";
    };

    extraArgs = mkOption {
      type = types.str;
      default = "";
      description = "Extra kernel command-line arguments.";
    };
  };
}
