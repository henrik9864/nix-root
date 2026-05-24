let
  contents = builtins.readDir ./.;

  projectDirs =
    contents
    |> builtins.attrNames
    |> builtins.filter (name: contents.${name} == "directory")
    |> builtins.filter (name: builtins.pathExists (./. + "/${name}/project.nix"));
in
  projectDirs
  |> map (dir: ./. + "/${dir}/project.nix")
