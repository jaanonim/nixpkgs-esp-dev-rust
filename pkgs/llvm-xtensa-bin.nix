{ version ? "21.1.3_20260304"
, hash ? "sha256-IPyu9+AhXl+d9TI4rTSKtmlwJ7O5UtMAxVgNunrITMU="
, stdenv
, lib
, fetchurl
, autoPatchelfHook
, zlib
, libxml2
}:


assert stdenv.system == "x86_64-linux";

stdenv.mkDerivation rec {
  pname = "xtensa-llvm-toolchain";
  inherit version;
  src = fetchurl {
    url = "https://github.com/espressif/llvm-project/releases/download/esp-${version}/clang-esp-${version}-x86_64-linux-gnu.tar.xz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ zlib libxml2 ];

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -r . $out
  '';

  meta = with lib; {
    description = "Xtensa LLVM tool chain";
    homepage = "https://github.com/espressif/llvm-project";
    license = licenses.gpl3;
  };
}

