{pkgs ? import ../default.nix}: let
  commons = (import ../lib/common-rust.nix) {inherit pkgs;};
in
  pkgs.mkShell {
    name = "esp-idf-full-shell-rust";

    buildInputs = with pkgs;
      [
        esp-idf-full
      ]
      ++ commons.buildInputs;

    shellHook = commons.shellHook;
  }
