final: prev:
rec {
  # Import our local python package set once against the original python3Packages
  # so we can pin specific packages (urllib3) into the base python3Packages set
  # used by downstream builds. This avoids infinite recursion by using `prev`.
  previewCustom = prev.callPackage ./pkgs/esp-idf/python-packages.nix { pythonPackages = prev.python3Packages; };

  # Override the system python3Packages to use our pinned urllib3 from previewCustom.
  python3Packages = prev.python3Packages // { urllib3 = previewCustom.urllib3; };

  esp-idf-full = final.callPackage ./pkgs/esp-idf {
    fetchurl = final.fetchurl;

    zlib = final.zlib;
    libusb1 = final.libusb1;
    udev = final.udev;
    python3 = final.python3;
    python311 = final.python311;
    python312 = final.python312;
    glibc = final.glibc;
    libxml2_13 = final.libxml2_13;
  };

  esp-idf-esp32 = esp-idf-full.override {
    toolsToInclude = [
      "xtensa-esp-elf"
      "esp32ulp-elf"
      "openocd-esp32"
      "xtensa-esp-elf-gdb"
    ];
  };

  esp-idf-riscv = esp-idf-full.override {
    toolsToInclude = [
      "riscv32-esp-elf"
      "openocd-esp32"
      "riscv32-esp-elf-gdb"
    ];
  };

  esp-idf-esp32c3 = esp-idf-riscv;

  esp-idf-esp32s2 = esp-idf-full.override {
    toolsToInclude = [
      "xtensa-esp-elf"
      "esp32ulp-elf"
      "openocd-esp32"
      "xtensa-esp-elf-gdb"
    ];
  };

  esp-idf-esp32s3 = esp-idf-full.override {
    toolsToInclude = [
      "xtensa-esp32s3-elf"
      "esp32ulp-elf"
      "openocd-esp32"
      "xtensa-esp-elf-gdb"
    ];
  };

  # LLVM
  llvm-xtensa = prev.callPackage ./pkgs/llvm-xtensa-bin.nix { };
  llvm-xtensa-lib = prev.callPackage ./pkgs/llvm-xtensa-lib.nix { };

  # Rust
  rust-xtensa = (import ./pkgs/rust-xtensa-bin.nix { rust = prev.rust; callPackage = prev.callPackage; lib = prev.lib; stdenv = prev.stdenv; fetchurl = prev.fetchurl; });

  esp-idf-esp32c6 = esp-idf-riscv;

  esp-idf-esp32h2 = esp-idf-riscv;


}
