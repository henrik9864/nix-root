let
  contents = builtins.readDir ./.;

  dirs =
    builtins.filter
    (name: contents.${name} == "directory")
    (builtins.attrNames contents);

  hasProject = name:
    builtins.pathExists (./. + "/${name}/project.nix");

  projectDirs = builtins.filter hasProject dirs;
in
  map (dir: ./. + "/${dir}/project.nix") projectDirs
