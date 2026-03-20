{ version ? "21.1.3_20260304"
, hash ? "sha256-Cyr7TlcyFPQ+ouh/bg13n7v101o2EetK+EcK34aL+PI="
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
    url = "https://github.com/espressif/llvm-project/releases/download/esp-${version}/libs-clang-esp-${version}-x86_64-linux-gnu.tar.xz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ zlib libxml2 ];

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -r . $out
  '';

  meta = with lib; {
    description = "Xtensa LLVM tool chain libraries";
    homepage = "https://github.com/espressif/llvm-project";
    license = licenses.gpl3;
  };
}

