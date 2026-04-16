{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-custom.url = "path:./pkgs";
  };

  outputs = {
    self,
    nixpkgs,
    pkgs-custom,
  }: let
    overlays = [
      (final: prev: import ./pkgs/default.nix {callPackage = final.callPackage;})
    ];

    nativePkgs = import nixpkgs {
      system = "x86_64-linux";
      inherit overlays;
    };

    boards = import ./boards;

    evalProject = {
      projectModule,
      outputTarget ? "sd",
    }:
      import ./lib/options/options.nix {
        inherit nixpkgs overlays;
        extraArgs = {inherit boards;};
        modules = [
          projectModule
          {output.target = outputTarget;}
        ];
      };

    mkProject = {
      projectModule,
      outputTarget,
    }: let
      cfg = (evalProject {inherit projectModule outputTarget;}).config;

      bootloader = cfg.bootloader.package;
      kernel = import ./lib/kernel/mkKernel.nix {
        pkgs = cfg._pkgs;
        inherit cfg;
      };
      rootfs = import ./lib/rootfs/mkRootfs.nix {
        pkgs = cfg._pkgs;
        nativePkgs = cfg._nativePkgs;
        inherit cfg;
      };
      initrd = import ./lib/initrd/mkInitrd.nix {
        pkgs = cfg._nativePkgs;
        inherit rootfs;
      };
      image = import ./lib/image/mkImage.nix {
        pkgs = cfg._nativePkgs;
        inherit cfg bootloader kernel initrd rootfs;
      };
    in {
      inherit kernel rootfs initrd image cfg;
    };

    projectRegistry = import ./projects/projects.nix;

    mkProjectTargets = projectModule: let
      projectName = baseNameOf (builtins.dirOf projectModule);
      targetsList = (evalProject {inherit projectModule;}).config.output.targets;
    in {
      name = projectName;
      value = builtins.listToAttrs (map (target: {
          name = target;
          value = mkProject {
            inherit projectModule;
            outputTarget = target;
          };
        })
        targetsList);
    };

    projects = builtins.listToAttrs (map mkProjectTargets projectRegistry);

  in {
    images =
      builtins.mapAttrs (
        _: targets:
          builtins.mapAttrs (_: project: project.image) targets
      )
      projects;

    devShells.x86_64-linux =
      builtins.mapAttrs (
        _: targets:
          builtins.mapAttrs (
            _: project:
              import ./lib/shells/devshell/mkDevShell.nix {board = project;}
          )
          targets
      )
      projects;

    flashShells.x86_64-linux =
      builtins.mapAttrs (
        _: targets:
          import ./lib/shells/flashshell/mkFlashShell.nix {inherit targets;}
      )
      projects;
  };
}
