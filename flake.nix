{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    overlays = [
      (final: prev: import ./pkgs/default.nix {callPackage = final.callPackage;})
    ];

    boards = import ./boards;

    imageBuilderPath = target:
      if target == "sd" || target == "emmc"
      then ./lib/image/disk
      else ./lib/image + "/${target}";

    mkProjectTargets = projectModule: let
      projectName = baseNameOf (builtins.dirOf projectModule);

      evalCfg = outputTarget:
        (import ./lib/options/options.nix {
          inherit nixpkgs overlays;
          extraArgs = {inherit boards;};
          modules = [projectModule {output.target = outputTarget;}];
        })
        .config;

      # output.targets is board-defined; doesn't vary with outputTarget
      targetsList = (evalCfg "sd").output.targets;

      mkTarget = outputTarget: let
        cfg = evalCfg outputTarget;
        bootloader = cfg.bootloader.package;
        kernel = import ./lib/kernel/mkKernel.nix {pkgs = cfg._pkgs; inherit cfg;};
        rootfs = import ./lib/rootfs/mkRootfs.nix {
          pkgs = cfg._pkgs;
          nativePkgs = cfg._nativePkgs;
          inherit cfg;
        };
        initrd = cfg._nativePkgs.makeInitrd {
          name = "initrd";
          contents = [{object = rootfs; symlink = "/";}];
        };
        image = import (imageBuilderPath outputTarget) {
          pkgs = cfg._nativePkgs;
          inherit cfg bootloader kernel initrd rootfs;
        };
      in {inherit kernel rootfs initrd image cfg;};
    in {
      name = projectName;
      value = builtins.listToAttrs (map (t: {
          name = t;
          value = mkTarget t;
        })
        targetsList);
    };

    projects = builtins.listToAttrs (map mkProjectTargets (import ./projects/projects.nix));
  in {
    images =
      projects
      |> builtins.mapAttrs (
        _: targets: targets |> builtins.mapAttrs (_: project: project.image)
      );

    devShells.x86_64-linux =
      projects
      |> builtins.mapAttrs (
        _: targets:
          targets
          |> builtins.mapAttrs (_: project: import ./lib/shells/devshell/mkDevShell.nix {board = project;})
      );

    flashShells.x86_64-linux =
      projects
      |> builtins.mapAttrs
      (_: targets: import ./lib/shells/flashshell/mkFlashShell.nix {inherit targets;});
  };
}
