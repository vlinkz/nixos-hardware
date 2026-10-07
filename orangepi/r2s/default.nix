{ lib, pkgs, ... }:

{
  imports = [ ./firmware.nix ];

  config = {
    boot = {
      # K1 PCIe support needs Linux 7.3
      kernelPackages = lib.mkDefault (
        if lib.versionAtLeast pkgs.linuxPackages_latest.kernel.version "7.3" then
          pkgs.linuxPackages_latest
        else
          pkgs.linuxPackages_testing
      );

      kernelParams = [
        "console=ttyS0,115200n8"
        "earlycon"
      ];

      kernelPatches = [
        {
          name = "pci-spacemit-k1-ignore-link-partner-perst";
          patch = ./patches/linux/0001-PCI-spacemit-Ignore-link-partner-PERST-on-K1.patch;
        }
        # Built in, r8169 is probed from the async K1 PCIe probe and trips a request_module() warning
        {
          name = "orangepi-r2s-r8169-module";
          patch = null;
          structuredExtraConfig.R8169 = lib.kernel.module;
        }
      ];

      initrd.availableKernelModules = [
        "dwc3"
        "dwc3-generic-plat"
        "phy-k1-usb2"
        "k1_emac"
      ];

      loader = {
        grub.enable = lib.mkDefault false;
        generic-extlinux-compatible.enable = lib.mkDefault true;
      };
    };

    hardware.deviceTree = {
      name = lib.mkDefault "spacemit/k1-orangepi-r2s.dtb";
      overlays = [
        {
          name = "orangepi-r2s-cpufreq";
          dtsFile = ./cpufreq.dtso;
          filter = "k1-orangepi-r2s.dtb";
        }
      ];
    };
  };
}
