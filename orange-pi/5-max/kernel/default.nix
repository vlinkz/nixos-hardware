{ fetchFromGitHub
, lib
, linuxManualConfig
, stdenv
, ubootTools
, ...
}:
(linuxManualConfig rec {
  inherit lib stdenv;
  modDirVersion = "6.1.75";
  version = "${modDirVersion}-rk3588";
  src = fetchFromGitHub {
    owner = "armbian";
    repo = "linux-rockchip";
    rev = "v24.11.1";
    hash = "sha256-ZqEKQyFeE0UXN+tY8uAGrKgi9mXEp6s5WGyjVuxmuyM=";
  };
  configfile = ./linux-rk35xx-vendor.config;
  config = import ./linux-rk35xx-vendor.nix;
  extraMeta.branch = "rk-6.1-rkr3";
}).overrideAttrs (old: {
  name = "k"; # dodge uboot length limits
  nativeBuildInputs = old.nativeBuildInputs ++ [ ubootTools ];
})
