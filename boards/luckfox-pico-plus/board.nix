{
  targets = ["sd" "spinand"];

  module = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.kernel) yes no freeform;
  in rec {
  board.name = "luckfox-pico-plus";
  board.crossSystem = "armv7l-unknown-linux-gnueabihf";
  board.dts = "/arch/arm/boot/dts/rv1103g-luckfox-pico-plus.dts";

  board.dtbSource.git = {
    owner = "LuckfoxTECH";
    repo = "luckfox-pico";
    rev = "824b817f889c2cbff1d48fcdb18ab494a68f69d1";
    hash = "sha256-x5BC/hA9WCXqwrHJmcRv82NcWfV5jpOF+NTnRngRE70=";
    path = "sysdrv/source/kernel";
    sparseCheckout = ["sysdrv/source/kernel"];
  };

  bootloader.package = pkgs.uboot-luckfox-pico.override {
    defconfig = "luckfox_rv1106_uboot";
    bootcmd = "mtd read spi-nand0 0x01000000 0x1000000 0xE00000 && mtd read spi-nand0 0x03F00000 0x2000000 0x80000 && bootz 0x01000000 - 0x03F00000";
    configOverrides = {
      CONFIG_DEBUG = true;
      CONFIG_SPL_DEBUG = true;

      CONFIG_SPL_FIT_SIGNATURE = false;
      CONFIG_SPL_FIT_HW_CRYPTO = false;

      CONFIG_MTD = true;
      CONFIG_DM_MTD = true;
      CONFIG_MTD_SPI_NAND = true;
      CONFIG_SPI_NAND = true;
      CONFIG_SPL_SPI_NAND_SUPPORT = true;

      CONFIG_SPL_ROCKCHIP_BACK_TO_BROM = true;
      CONFIG_SPL_SPI_NAND_WINBOND = true;
    };
  };
  bootloader.files = [
    {
      file = "idblock.img";
      offset = 64;
    }
    {
      file = "uboot.img";
      offset = 16384;
    }
  ];

  flash.miniloader = pkgs.rkbin-miniloader.override {iniFile = "RV1106MINIALL";};
  flash.nand.totalSizeMiB = 128;
  flash.nand.dtFlashPath = "/spi@ffac0000/flash@0";

  flash.spinandPartitions = [
    {
      name = "env";
      sizeMiB = 8;
      offsetMiB = 0;
      flashFile = null;
    }
    {
      name = "uboot";
      sizeMiB = 4;
      offsetMiB = 8;
      flashFile = "firmware/uboot.img";
    }
    {
      name = "kernel";
      sizeMiB = 16;
      offsetMiB = 16;
      flashFile = "images/kernel.img";
    }
    {
      name = "dtb";
      sizeMiB = 2;
      offsetMiB = 32;
      flashFile = "images/devicetree.dtb";
    }
    {
      name = "rootfs";
      sizeMiB = null;
      offsetMiB = 34;
      flashFile = "images/rootfs.ubi";
    }
  ];

  kernel.version = "7.1-rc5";
  kernel.modDirVersion = "7.1.0-rc5";
  kernel.imageFile = "zImage";

  kernel.git = {
    owner = "torvalds";
    repo = "linux";
    rev = "v7.1-rc5";
    hash = "sha256-V4OO9854uQv9n0jirUVPBGaw2le3Ti9mY9AXCsz4ogg=";
  };

  kernel.patches = [
    {
      name = "rv1103-machine-compat";
      patch = ./rv1103-machine-compat.patch;
    }
    {
      name = "rv1106-clk-compat";
      patch = ./rv1106-clk-compat.patch;
    }
    {
      name = "rv1106-pinctrl-compat";
      patch = ./rv1106-pinctrl-compat.patch;
    }
    {
      name = "rv1106-gmac-compat";
      patch = ./rv1106-gmac-compat.patch;
    }
  ];

  kernel.structuredConfig = {
    # ARM / Rockchip platform
    ARCH_MULTI_V7 = yes;
    ARCH_ROCKCHIP = yes;
    ARM_PATCH_PHYS_VIRT = yes;
    AUTO_ZRELADDR = yes;
    VFP = yes;
    NEON = yes;
    AEABI = yes;
    HIGHMEM = yes;
    RD_GZIP = yes;

    # IRQ / timer / DT
    OF = yes;
    OF_FLATTREE = yes;
    OF_EARLY_FLATTREE = yes;
    OF_ADDRESS = yes;
    OF_IRQ = yes;
    OF_RESERVED_MEM = yes;
    IRQCHIP = yes;
    ARM_GIC = yes;
    ARM_ARCH_TIMER = yes;

    # Clocks / reset / pinctrl / GPIO
    COMMON_CLK = yes;
    COMMON_CLK_ROCKCHIP = yes;
    RESET_CONTROLLER = yes;
    PINCTRL = yes;
    PINCTRL_ROCKCHIP = yes;
    GPIOLIB = yes;
    GPIO_SYSFS = yes;
    ROCKCHIP_PM_DOMAINS = yes;
    ROCKCHIP_GRF = yes;
    ROCKCHIP_IODOMAIN = yes;
    CLK_RV1103B = yes;

    # Console / printk
    TTY = yes;
    VT = yes;
    VT_CONSOLE = yes;
    PRINTK = yes;
    BUG = yes;
    DEBUG_KERNEL = yes;
    KALLSYMS = yes;
    KALLSYMS_ALL = yes;
    PANIC_ON_OOPS = no;
    SERIAL_EARLYCON = yes;
    EARLY_PRINTK = yes;
    IGNORE_LOGLEVEL = yes;

    # 8250 / DW UART
    SERIAL_8250 = yes;
    SERIAL_8250_CONSOLE = yes;
    SERIAL_8250_DW = yes;
    SERIAL_OF_PLATFORM = yes;
    SERIAL_8250_NR_UARTS = freeform "8";
    SERIAL_8250_RUNTIME_UARTS = freeform "8";

    # Do NOT enable vendor Rockchip FIQ console for upstream
    FIQ_DEBUGGER = no;

    # Initramfs / root basics
    BLK_DEV_INITRD = yes;
    DEVTMPFS = yes;
    DEVTMPFS_MOUNT = yes;
    TMPFS = yes;
    EXT4_FS = yes;

    # MMC / SD
    MMC = yes;
    MMC_BLOCK = yes;
    MMC_DW = yes;
    MMC_DW_ROCKCHIP = yes;
    MMC_SDHCI = yes;
    MMC_SDHCI_PLTFM = yes;
    MMC_SDHCI_OF_DWCMSHC = yes;

    # Ethernet (GMAC + integrated FePHY)
    NETDEVICES = yes;
    ETHERNET = yes;
    NET_VENDOR_STMICRO = yes;
    STMMAC_ETH = yes;
    STMMAC_PLATFORM = yes;
    DWMAC_ROCKCHIP = yes;
    PHYLIB = yes;
    MOTORCOMM_PHY = yes;

    # SPI / SPI NAND
    SPI = yes;
    SPI_MASTER = yes;
    SPI_MEM = yes;
    SPI_ROCKCHIP = yes;
    SPI_ROCKCHIP_SFC = yes;

    MTD = yes;
    MTD_BLOCK = yes;
    MTD_CMDLINE_PARTS = yes;
    MTD_OF_PARTS = yes;
    MTD_SPI_NAND = yes;
    MTD_RAW_NAND = no;

    MTD_SPINAND_WINBOND = yes;
    MTD_SPINAND_GIGADEVICE = yes;
    MTD_SPINAND_MACRONIX = yes;
    MTD_SPINAND_TOSHIBA = yes;

    # UBI / UBIFS
    UBI = yes;
    UBI_BLOCK = yes;
    UBIFS_FS = yes;
    UBIFS_FS_LZO = yes;
    UBIFS_FS_ZLIB = yes;

    # Compression
    ZLIB_INFLATE = yes;
    ZLIB_DEFLATE = yes;
    LZO_COMPRESS = yes;
    LZO_DECOMPRESS = yes;

    # JFFS2
    JFFS2_FS = yes;
    JFFS2_FS_WRITEBUFFER = yes;
    JFFS2_ZLIB = yes;
    JFFS2_LZO = yes;
    JFFS2_RTIME = yes;
  };

  image.bootPadding = 8;
  image.rootfsPadding = 16;

  board.dtbPatches = ''
    fdtput -r $DTB_PATH /psci
    fdtput -t s $DTB_PATH /serial@ff4c0000 status okay
    fdtput -d $DTB_PATH /serial@ff4c0000 clocks
    fdtput -d $DTB_PATH /serial@ff4c0000 clock-names
    fdtput -d $DTB_PATH /serial@ff4c0000 pinctrl-0
    fdtput -d $DTB_PATH /serial@ff4c0000 pinctrl-names
    fdtput -d $DTB_PATH /serial@ff4c0000 dmas
    fdtput -d $DTB_PATH /ethernet@ffa80000 nvmem-cells
    fdtput -d $DTB_PATH /ethernet@ffa80000 nvmem-cell-names
    fdtput -d $DTB_PATH /ethernet@ffa80000/mdio/ethernet-phy@2 nvmem-cells
    fdtput -d $DTB_PATH /ethernet@ffa80000/mdio/ethernet-phy@2 nvmem-cell-names
  '';

  serial.console = "ttyS2,115200";
  serial.earlycon = "uart8250,mmio32,0xff4c0000,115200";
  };
}
