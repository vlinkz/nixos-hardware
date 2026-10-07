{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.orangepi-r2s;
in
{
  options.hardware.orangepi-r2s = {
    uboot.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./uboot.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./uboot.nix { }";
      description = ''
        Mainline U-Boot build for the Orange Pi R2S. Must provide
        `bootinfo_emmc.bin`, `FSBL.bin` and `u-boot.itb`.
      '';
    };
  };

  config.system.build = {
    uboot = cfg.uboot.package;

    updater-emmc = pkgs.writeShellApplication {
      name = "orangepi-r2s-firmware-update-emmc";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        dev=''${1-}
        if [ -z "$dev" ]; then
          for boot0 in /dev/mmcblk[0-9]boot0; do
            [ -e "$boot0" ] && dev=''${boot0%boot0} && break
          done
        fi
        if [ -z "$dev" ] || [ ! -b "$dev" ] || [ ! -b "''${dev}boot0" ]; then
          echo "Usage: orangepi-r2s-firmware-update-emmc [/dev/mmcblkN]" >&2
          echo "No eMMC with a boot0 partition found." >&2
          exit 1
        fi
        name=$(basename "$dev")

        itb_sectors=$(( ($(stat -c %s ${config.system.build.uboot}/u-boot.itb) + 511) / 512 ))
        first_part=$(cat "/sys/block/$name/''${name}p1/start")
        if [ $(( 2048 + itb_sectors )) -gt "$first_part" ]; then
          echo "u-boot.itb does not fit in front of the first partition of $dev" >&2
          exit 1
        fi

        force_ro=/sys/block/''${name}boot0/force_ro
        echo 0 >"$force_ro"
        trap 'echo 1 >"$force_ro"' EXIT

        dd if=${config.system.build.uboot}/bootinfo_emmc.bin of="''${dev}boot0" conv=fsync,notrunc
        dd if=${config.system.build.uboot}/FSBL.bin of="''${dev}boot0" bs=512 seek=1 conv=fsync,notrunc
        dd if=${config.system.build.uboot}/u-boot.itb of="$dev" bs=512 seek=2048 conv=fsync,notrunc
        echo "Updated U-Boot on $dev"
      '';
    };
  };
}
