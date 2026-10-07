{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  openssl,
  python3,
}:

stdenvNoCC.mkDerivation {
  pname = "spacemit-k1-image-tool";
  version = "0-unstable-2026-09-10";

  src = fetchFromGitHub {
    owner = "spacemit-com";
    repo = "uboot-2022.10";
    rev = "7f51f4453f9811eeaafbdd839b1bf1b0cc27a413"; # branch k1-bl-v2.2.y
    nonConeMode = true;
    sparseCheckout = [
      "/tools/build_binary_file.py"
      "/tools/common_decorator.py"
      "/board/spacemit/k1-x/configs/fsbl.json"
      "/board/spacemit/k1-x/configs/bootinfo_emmc.json"
      "/board/spacemit/k1-x/configs/key/"
    ];
    hash = "sha256-nT2PLg88k40k+bCme9XTupAWwurnP7B35FvFReK9dnY=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/libexec/spacemit-k1-image-tool \
      tools/build_binary_file.py tools/common_decorator.py

    mkdir -p $out/share/spacemit-k1-image-tool
    cp -r board/spacemit/k1-x/configs/{fsbl.json,bootinfo_emmc.json,key} \
      $out/share/spacemit-k1-image-tool/

    makeWrapper ${python3.interpreter} $out/bin/spacemit-k1-image-tool \
      --add-flags $out/libexec/spacemit-k1-image-tool/build_binary_file.py \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}

    runHook postInstall
  '';

  meta = {
    description = "SpacemiT K1 boot ROM image (FSBL/bootinfo) generator";
    homepage = "https://github.com/spacemit-com/uboot-2022.10";
    license = lib.licenses.gpl2Plus;
    mainProgram = "spacemit-k1-image-tool";
    platforms = lib.platforms.all;
  };
}
