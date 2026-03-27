{pkgs, ...}: {
  buildInputs = with pkgs; [
    git
    wget
    gnumake

    flex
    bison
    gperf
    pkg-config
    cargo-generate
    openssl

    cmake
    ninja

    ncurses5

    llvm-xtensa
    llvm-xtensa-lib
    rust-xtensa

    espflash
    ldproxy

    python3
    python3Packages.pip
    python3Packages.virtualenv
  ];
  shellHook = ''
    # fixes libstdc++ issues and libgl.so issues
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [pkgs.libxml2 pkgs.zlib pkgs.stdenv.cc.cc.lib pkgs.openssl]}
    export ESP_IDF_VERSION=6.0
    export LIBCLANG_PATH=${pkgs.llvm-xtensa-lib}/lib
    export RUSTFLAGS="--cfg espidf_time64"
  '';
}
