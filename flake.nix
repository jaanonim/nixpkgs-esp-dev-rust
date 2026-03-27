{
  description = "ESP32 development tools";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    {
      overlays.default = import ./overlay.nix;
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
        config.permittedInsecurePackages = [
          "python3.13-ecdsa-0.19.1"
        ];
      };
    in {
      packages = {
        inherit
          (pkgs)
          esp-idf-full
          esp-idf-esp32
          esp-idf-esp32c3
          esp-idf-esp32s2
          esp-idf-esp32s3
          esp-idf-esp32c6
          esp-idf-esp32h2
          espflash
          ldproxy
          llvm-xtensa
          llvm-xtensa-lib
          rust-xtensa
          ;
      };

      devShells = rec {
        default = esp32-idf-rust;

        esp-idf-full = import ./shells/esp-idf-full.nix {inherit pkgs;};
        esp-idf-full-rust = import ./shells/esp-idf-full-rust.nix {inherit pkgs;};
        esp32-idf = import ./shells/esp32-idf.nix {inherit pkgs;};
        esp32-idf-rust = import ./shells/esp32-idf-rust.nix {inherit pkgs;};
        esp32c3-idf = import ./shells/esp32c3-idf.nix {inherit pkgs;};
        esp32c3-idf-rust = import ./shells/esp32c3-idf-rust.nix {inherit pkgs;};
        esp32s2-idf = import ./shells/esp32s2-idf.nix {inherit pkgs;};
        esp32s2-idf-rust = import ./shells/esp32s2-idf-rust.nix {inherit pkgs;};
        esp32s3-idf = import ./shells/esp32s3-idf.nix {inherit pkgs;};
        esp32s3-idf-rust = import ./shells/esp32s3-idf-rust.nix {inherit pkgs;};
        esp32c6-idf = import ./shells/esp32c6-idf.nix {inherit pkgs;};
        esp32h2-idf = import ./shells/esp32h2-idf.nix {inherit pkgs;};
      };

      checks = import ./tests/build-idf-examples.nix {inherit pkgs;};
    });
}
