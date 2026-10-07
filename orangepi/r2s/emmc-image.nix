{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  inherit (config.system.build) uboot;
in
{
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  image.baseName = lib.mkDefault "nixos-orangepi-r2s-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  sdImage = {
    firmwareSize = lib.mkDefault 16;
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
    postBuildCommands = ''
      if [ "$(stat -c %s ${uboot}/u-boot.itb)" -gt $(( (${toString config.sdImage.firmwarePartitionOffset} - 1) * 1024 * 1024 )) ]; then
        echo "u-boot.itb does not fit in front of the first partition" >&2
        exit 1
      fi
      dd if=${uboot}/u-boot.itb of=$img bs=512 seek=2048 conv=notrunc
    '';
  };
}
