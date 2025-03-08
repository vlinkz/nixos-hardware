{ config, lib, ... }:
let
  cfg = config.hardware.milkv.mars.uartDebug;
in
{
  options.hardware.milkv.mars.uartDebug = {
    enable = lib.mkEnableOption "UART2 serial console" // {
      default = true;
    };
    baudRate = lib.mkOption {
      type = lib.types.int;
      default = 1500000;
      description = "Baud rate for the UART2 serial console";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "earlycon=sbi"
      "console=ttyS0,${toString cfg.baudRate}"
    ];
  };
}
