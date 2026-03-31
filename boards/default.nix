let
  contents = builtins.readDir ./.;

  dirs = builtins.filter
    (name: contents.${name} == "directory")
    (builtins.attrNames contents);

  hasBoard = name:
    builtins.pathExists (./. + "/${name}/board.nix");

  boardDirs = builtins.filter hasBoard dirs;

in builtins.listToAttrs (map (dir: {
  name  = dir;
  value = ./. + "/${dir}/board.nix";
}) boardDirs)