{pkgs ? import ../default.nix}: let
  commons = (import ../lib/common-rust.nix) {inherit pkgs;};
in
  pkgs.mkShell {
    name = "esp-idf-esp32-shell-rust";

    buildInputs = with pkgs;
      [
        esp-idf-esp32
      ]
      ++ commons.buildInputs;

    shellHook = commons.shellHook;
  }
