let
  contents = builtins.readDir ./.;

  dirs = builtins.filter
    (name: contents.${name} == "directory")
    (builtins.attrNames contents);

  hasProject = name:
    builtins.pathExists (./. + "/${name}/project.nix");

  projectDirs = builtins.filter hasProject dirs;

in builtins.listToAttrs (map (dir: {
  name  = dir;
  value = ./. + "/${dir}/project.nix";
}) projectDirs)