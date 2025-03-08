{ config, pkgs, lib, ... }:
let
  cfg = config.hardware.milkvmars;
in
{
  options = {
    hardware.milkvmars = {
      opensbi = {
        src = lib.mkOption {
          description = "MilkV Mars OpenSBI source";
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        patches = lib.mkOption {
          description = "List of patches to apply to the MilkV Mars OpenSBI source";
          type = lib.types.nullOr (lib.types.listOf lib.types.package);
          default = null;
        };
      };
      uboot = {
        src = lib.mkOption {
          description = "MilkV Mars U-boot source";
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        patches = lib.mkOption {
          description = "List of patches to apply to the MilkV Mars U-boot source";
          type = lib.types.nullOr (lib.types.listOf lib.types.package);
          default = null;
        };
      };
    };
  };

  config = {
    system.build = {
      opensbi = (pkgs.callPackage ./opensbi.nix {}).overrideAttrs (f: p: {
        src = if cfg.opensbi.src != null then cfg.opensbi.src else p.src;
        patches = if cfg.opensbi.patches != null then cfg.opensbi.patches else (p.patches or []);
      });

      uboot = (pkgs.callPackage ./uboot.nix { inherit (config.system.build) opensbi; }).overrideAttrs (f: p: {
        src = if cfg.uboot.src != null then cfg.uboot.src else p.src;
        patches = if cfg.uboot.patches != null then cfg.uboot.patches else (p.patches or []);
      });

      updater-flash = pkgs.writeShellApplication {
        name = "mars-firmware-update-flash";
        runtimeInputs = [ pkgs.mtdutils ];
        text = ''
          flashcp -v ${config.system.build.uboot}/u-boot-spl.bin.normal.out /dev/mtd0
          flashcp -v ${config.system.build.uboot}/u-boot.itb /dev/mtd2
        '';
      };

      updater-sd = pkgs.writeShellApplication {
        name = "mars-firmware-update-sd";
        runtimeInputs = [ ];
        text = ''
          dd if=${config.system.build.uboot}/u-boot-spl.bin.normal.out of=/dev/mmcblk0p1 conv=fsync
          dd if=${config.system.build.uboot}/u-boot.itb of=/dev/mmcblk0p2 conv=fsync
        '';
      };
    };
  };
}
