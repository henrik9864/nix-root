{
  pkgs,
  boards,
  ...
}: let
  inherit (pkgs.lib.kernel) yes;
in {
  imports = [boards.luckfox-pico-plus.module];

  networking.hostName = "foxhole";
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];
  networking.interfaces.eth0.useDHCP = true;

  environment.systemPackages = [
    pkgs.pkgsStatic.tailscale
  ];

  # Kernel additions on top of the luckfox-pico-plus base config
  kernel.structuredConfig = {
    # TUN device for Tailscale's virtual interface
    TUN = yes;

    # Netfilter — needed for subnet routing / NAT masquerade
    NETFILTER = yes;
    NF_CONNTRACK = yes;

    # nftables (preferred by modern Tailscale)
    NF_TABLES = yes;
    NF_TABLES_IPV4 = yes;
    NF_NAT = yes;
    NFT_NAT = yes;
    NFT_MASQ = yes;

    # iptables (fallback for older Tailscale behaviour)
    NETFILTER_XTABLES = yes;
    IP_NF_IPTABLES = yes;
    IP_NF_FILTER = yes;
    IP_NF_NAT = yes;
    NETFILTER_XT_MATCH_CONNTRACK = yes;
    NETFILTER_XT_TARGET_MASQUERADE = yes;
  };

  rootfs.extraCommands = ''
    mkdir -p $out/var/lib/tailscale $out/var/run/tailscale
  '';

  rootfs.extraInitCommands = ''
    # Enable IP forwarding for subnet routing
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

    # Tailscale state lives on the persistent UBIFS rootfs
    mkdir -p /var/lib/tailscale /var/run/tailscale

    tailscaled \
      --state=/var/lib/tailscale/tailscaled.state \
      --socket=/var/run/tailscale/tailscaled.sock \
      &
  '';

  # After first boot, run:
  #   tailscale up --advertise-routes=<local-subnet/mask> --accept-routes
  # and enable subnet routing in the Tailscale admin console.
}
