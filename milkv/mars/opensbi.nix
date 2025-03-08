{ opensbi }:

opensbi.overrideAttrs (attrs: {
  makeFlags = attrs.makeFlags ++ [
    # opensbi generic platform default FW_TEXT_START is 0x80000000
    # For JH7110, need to specify the FW_TEXT_START to 0x40000000
    # Otherwise, the fw_payload.bin downloading via jtag will not run.
    # https://github.com/milkv-mars/mars-buildroot-sdk/blob/1fd6bac9f2efde47fbb8afd28d2903c49f893e3f/Makefile#L280
    # Also matches u-boot documentation: https://docs.u-boot.org/en/latest/board/starfive/milk-v_mars.html
    "FW_TEXT_START=0x40000000"
    "FW_OPTIONS=0"
  ];
})
