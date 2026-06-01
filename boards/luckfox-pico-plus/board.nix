{
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
    #defconfig = "luckfox_rv1106_spi_nand_tb";
    defconfig = "luckfox_rv1106_uboot";
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
      #CONFIG_SPL_SPI_LOAD = true;

      #CONFIG_SPL_MAX_SIZE = "0x10000";

      #CONFIG_SPL_LZMA = false;
      #CONFIG_SPL_ZLIB = false;
      #CONFIG_SPL_GZIP = false;

      #CONFIG_SPL_SPI_NAND_MTD = true;
      #CONFIG_SPL_MTD_SPINAND = true;
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

  flash.method = "spinand";
  flash.miniloader = pkgs.rkbin-miniloader.override {iniFile = "RV1106MINIALL";};

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
    CLK_RV1106 = yes;

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

    # SPI / SPI NAND
    SPI = yes;
    SPI_MASTER = yes;
    SPI_MEM = yes;
    SPI_ROCKCHIP = yes;

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

    # Optional JFFS2
    JFFS2_FS = yes;
    JFFS2_FS_WRITEBUFFER = yes;
    JFFS2_ZLIB = yes;
    JFFS2_LZO = yes;
    JFFS2_RTIME = yes;
  };

  image.bootPadding = 8;
  image.rootfsPadding = 16;

  serial.console = "ttyS2,115200";

  output.targets = ["sd" "spinand"];
}
