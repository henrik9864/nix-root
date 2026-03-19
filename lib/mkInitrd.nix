{ pkgs, rootfs }:

pkgs.makeInitrd {
  name = "initrd";
  contents = [
    {
      object  = rootfs;
      symlink = "/";
    }
  ];
}