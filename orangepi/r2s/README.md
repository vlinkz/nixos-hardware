# Creating an eMMC image

Create and configure the `flake.nix` file:
``` nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:nixos/nixos-hardware";

  outputs = { nixpkgs, nixos-hardware, ... }: {
    nixosConfigurations.r2s = nixpkgs.lib.nixosSystem {
      modules = [
        nixos-hardware.nixosModules.orangepi-r2s
        "${nixos-hardware}/orangepi/r2s/emmc-image.nix"
        {
          # Additional configuration goes here

          sdImage.compressImage = false;

          nixpkgs.hostPlatform = "riscv64-linux";
          # nixpkgs.buildPlatform = "x86_64-linux"; # to cross-compile

          system.stateVersion = "26.11";
        }
      ];
    };
  };
}
```

Build the eMMC image.

``` sh
nix build .#nixosConfigurations.r2s.config.system.build.sdImage
```

# Flashing

Write `bootinfo_emmc.bin` and `FSBL.bin` from `config.system.build.uboot` to
the eMMC `boot0` partition at offsets 0 and 512, and the image to the eMMC user
area. Mainline U-Boot can't do this over USB yet, so the first install needs
the vendor's flashing binaries.

# Updating the bootloader

Install the firmware update script
``` nix
environment.systemPackages = [ config.system.build.updater-emmc ];
```
Then run as root
``` sh
orangepi-r2s-firmware-update-emmc
```
