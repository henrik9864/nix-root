{ nativePkgs }:

let
  lib = nativePkgs.lib;
in

name: opts:

let
  setMac = lib.optionalString (opts.mac != null)
    "ip link set dev ${name} address ${opts.mac}";

  addGateway = lib.optionalString (opts.gateway != null)
    "ip route add default via ${opts.gateway} dev ${name} 2>/dev/null || true";
in

''
  ip link add ${name} type dummy
  ${setMac}
  ip addr add ${opts.address} dev ${name}
  ip link set dev ${name} up
  ${addGateway}
''