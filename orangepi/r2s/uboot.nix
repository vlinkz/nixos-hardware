{
  lib,
  buildUBoot,
  buildPackages,
  fetchFromGitHub,
  fetchurl,
  opensbi,
}:

let
  ddrFirmware = fetchurl {
    url = "https://raw.githubusercontent.com/spacemit-com/spacemit-firmware/5969642a5b46fee5ba7f21ca54c3129bff7bb049/k1/v0.2/ddr_fw.bin";
    hash = "sha256-TKcp2uOVgP5tUv9qHq2V/RjNY5TJQsxKMjiCzPKEAUg=";
  };

  imageTool = buildPackages.callPackage ./image-tool.nix { };

  # OpenSBI < 1.9 randomly hangs at boot emulating misaligned vector accesses
  opensbi' =
    if lib.versionOlder opensbi.version "1.9" then
      opensbi.overrideAttrs (
        finalAttrs: _: {
          version = "1.9";
          src = fetchFromGitHub {
            owner = "riscv-software-src";
            repo = "opensbi";
            tag = "v${finalAttrs.version}";
            hash = "sha256-3RXsdo5e494odYtcRMMtAwes2LLniohHlOXEWy6CmrU=";
          };
        }
      )
    else
      opensbi;
in
(buildUBoot {
  version = "2026.10-unstable-2026-10-05";

  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "8d7bc8add17bbc69a58dfe0002eea039dd2dc1bc";
    hash = "sha256-LsGVlAVcFwWFCQv/juoDvBMNL/xJXnW85rv85K7SZKg=";
  };

  patches = [
    ./patches/u-boot/0001-board-spacemit-k1-don-t-panic-when-no-SPI-controller.patch
    ./patches/u-boot/0002-board-spacemit-k1-add-default-environment.patch
    ./patches/u-boot/0003-board-spacemit-k1-add-Orange-Pi-R2S-support.patch
  ];

  defconfig = "orangepi_r2s_defconfig";

  env = {
    OPENSBI = "${opensbi'}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin";
    DDR_FW_FILE = ddrFirmware;
  };

  filesToInstall = [
    "bootinfo_emmc.bin"
    "FSBL.bin"
    "u-boot-spl-ddr.bin"
    "u-boot.itb"
  ];

  extraMeta = {
    platforms = [ "riscv64-linux" ];
    license = with lib.licenses; [
      gpl2Plus
      unfreeRedistributableFirmware
    ];
  };
}).overrideAttrs
  (prev: {
    pname = "uboot-orangepi-r2s";

    postBuild = (prev.postBuild or "") + ''
      mkdir sign
      cp -r --no-preserve=mode ${imageTool}/share/spacemit-k1-image-tool sign/configs
      cp u-boot-spl-ddr.bin sign/u-boot-spl.bin
      ${lib.getExe imageTool} -c sign/configs/fsbl.json -o FSBL.bin
      ${lib.getExe imageTool} -c sign/configs/bootinfo_emmc.json -o bootinfo_emmc.bin
    '';
  })
