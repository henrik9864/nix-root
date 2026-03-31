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

    evalProject = { projectModule, outputTarget ? "sd" }:
      import ./lib/options/options.nix {
        inherit nixpkgs overlays;
        modules = [
          projectModule
          { output.target = outputTarget; }
        ];
      };

    mkProject = { projectModule, outputTarget }:
    let
      eval = evalProject { inherit projectModule outputTarget; };
      cfg  = eval.config;

      bootloader = cfg.bootloader.package;
      kernel     = import ./lib/kernel/mkKernel.nix  { pkgs = cfg._pkgs;                               inherit cfg; };
      rootfs     = import ./lib/rootfs/mkRootfs.nix  { pkgs = cfg._pkgs; nativePkgs = cfg._nativePkgs; inherit cfg; };
      initrd     = import ./lib/initrd/mkInitrd.nix  { pkgs = cfg._nativePkgs;                         inherit rootfs; };
      image      = import ./lib/image/mkImage.nix   { pkgs = cfg._nativePkgs; inherit cfg bootloader kernel initrd rootfs; };
    in {
      inherit kernel rootfs initrd image cfg;
    };

    mkDevShell = { board }:
      import ./lib/devshell/mkDevShell.nix { inherit board; };

    targetsFor = projectModule:
      (evalProject { inherit projectModule; }).config.output.targets;

    projectRegistry = import ./projects/projects.nix;

    projects = builtins.mapAttrs (_: projectModule:
      let
        targets = targetsFor projectModule;
      in builtins.listToAttrs (map (target: {
        name  = target;
        value = mkProject {
          inherit projectModule;
          outputTarget = target;
        };
      }) targets)
    ) projectRegistry;

  in {
    packages.x86_64-linux =
      builtins.mapAttrs (_: targets:
        builtins.mapAttrs (_: project: project.image) targets
      ) projects;

    devShells.x86_64-linux =
      builtins.mapAttrs (_: targets:
        let
          firstTarget = builtins.head (builtins.attrValues targets);
        in mkDevShell { board = firstTarget; }
      ) projects;
  };
}