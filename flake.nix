{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-custom.url = "path:./pkgs";
  };

  outputs = { self, nixpkgs, pkgs-custom }:
  let
    overlays = [
      (final: prev: import ./pkgs/default.nix { callPackage = final.callPackage; })
    ];

    nativePkgs = import nixpkgs {
      system = "x86_64-linux";
      inherit overlays;
    };

    boards = import ./boards;

    evalProject = { projectModule, outputTarget ? "sd" }:
      import ./lib/options/options.nix {
        inherit nixpkgs overlays;
        extraArgs = { inherit boards; };
        modules = [
          projectModule
          { output.target = outputTarget; }
        ];
      };

    mkProject = { projectModule, outputTarget }:
    let
      cfg = (evalProject { inherit projectModule outputTarget; }).config;

      bootloader = cfg.bootloader.package;
      kernel     = import ./lib/kernel/mkKernel.nix  { pkgs = cfg._pkgs;                               inherit cfg; };
      rootfs     = import ./lib/rootfs/mkRootfs.nix  { pkgs = cfg._pkgs; nativePkgs = cfg._nativePkgs; inherit cfg; };
      initrd     = import ./lib/initrd/mkInitrd.nix  { pkgs = cfg._nativePkgs;                         inherit rootfs; };
      image      = import ./lib/image/mkImage.nix   { pkgs = cfg._nativePkgs; inherit cfg bootloader kernel initrd rootfs; };
    in {
      inherit kernel rootfs initrd image cfg;
    };

    projectRegistry = import ./projects/projects.nix;

    projects = builtins.mapAttrs (_: projectModule:
      let
        targets = (evalProject { inherit projectModule; }).config.output.targets;
      in builtins.listToAttrs (map (target: {
        name  = target;
        value = mkProject {
          inherit projectModule;
          outputTarget = target;
        };
      }) targets)
    ) projectRegistry;

    mkAllImages = name: targets:
      let
        images = builtins.mapAttrs (_: project: project.image) targets;
        copyCommands = builtins.concatStringsSep "\n"
          (nativePkgs.lib.mapAttrsToList
            (target: image: "cp -r ${image}/* $out/")
            images);
      in nativePkgs.runCommand "${name}-all" {} ''
        mkdir -p $out
        ${copyCommands}
      '';

  in {
    packages.x86_64-linux =
      builtins.mapAttrs mkAllImages projects;

    images = builtins.mapAttrs (_: targets:
      builtins.mapAttrs (_: project: project.image) targets
    ) projects;

    devShells.x86_64-linux =
      builtins.mapAttrs (_: targets:
        let
          board = builtins.head (builtins.attrValues targets);
        in import ./lib/devshell/mkDevShell.nix { inherit board; }
      ) projects;

    flashShells.x86_64-linux =
      builtins.mapAttrs (_: targets:
        let
          board = builtins.head (builtins.attrValues targets);
        in import ./lib/devshell/mkFlashShell.nix { inherit board; }
      ) projects;
  };
}