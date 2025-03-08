{ config, lib, ... }:
{
  imports = [
    ./firmware.nix
    ./uart.nix
  ];

  boot = {
    consoleLogLevel = lib.mkDefault 7;

    initrd.availableKernelModules = [ "dw_mmc_starfive" ];

    loader = {
      grub.enable = lib.mkDefault false;
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };
  };

  hardware = {
    deviceTree = {
      enable = true;
      name = lib.mkDefault "starfive/jh7110-milkv-mars.dtb";
    };
    enableRedistributableFirmware = lib.mkDefault true;
  };

  assertions = [
    {
      assertion = lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.11";
      message = "The MilkV Mars requires at least mainline kernel version 6.11 for minimum hardware support.";
    }
  ];
}
