let
  contents = builtins.readDir ./.;

  boardDirs =
    contents
    |> builtins.attrNames
    |> builtins.filter (name: contents.${name} == "directory")
    |> builtins.filter (name: builtins.pathExists (./. + "/${name}/board.nix"));
in
  boardDirs
  |> map (dir: {
    name = dir;
    value = import (./. + "/${dir}/board.nix");
  })
  |> builtins.listToAttrs
