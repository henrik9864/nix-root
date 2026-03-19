{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.serial = {
    console = mkOption {
      type = types.str;
      default = "ttyS2,1500000";
      description = "Kernel serial console argument.";
    };

    extraArgs = mkOption {
      type = types.str;
      default = "";
      description = "Extra kernel command-line arguments.";
    };
  };
}