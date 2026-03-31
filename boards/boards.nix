{
  radxaCm5 = {
    sd   = { boardModule = ./radxa-cm5/board.nix; outputTarget = "sd"; };
    emmc = { boardModule = ./radxa-cm5/board.nix; outputTarget = "emmc"; };
  };

  luckfoxPicoPlus = {
    sd = { boardModule = ./luckfox-pico-plus/board.nix; outputTarget = "sd"; };
  };
}