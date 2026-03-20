# Flake Upgrade Execution Plan (nixos-unstable + custom package refresh + ESP8266 removal)

## Progress Snapshot (as of 2026-03-20)

- ✅ Phase B: `flake.nix` now tracks `nixos-unstable` and `flake.lock` points at an unstable revision.
- ✅ Phase C: ESP8266 support removed from public outputs and tests (branch/commit exists that removed esp8266 subtree and references).
- ✅ Phase D: ESP-IDF core overlays and Python package pins now aligned to v6.0; Nix evaluation and build succeed for esp-idf-full (with insecure python workaround for ecdsa, see Phase D notes). Legacy eval/override issues addressed. Validation of example/test outputs and other targets is ongoing; Phase E is next.
- 🔲 Phase E: LLVM and Rust xtensa binaries still use older planned versions and need bumping.
 - 🔲 Phase F: Shell environment variables still export `ESP_IDF_VERSION=v4.4.1` (needs alignment once ESP-IDF/package pins are final).
- ⚠️ A short stabilization step is required (see Phase D0) to make the current tree evaluable before further bumps — there are a few eval/runtime regressions introduced during the refresh (notably an overlay `urllib3` override mismatch).
- ℹ️ README still needs update to reflect the current toolchain and removed targets.

---

## 1) Goal and scope

Upgrade this repository to current upstream versions while:

1. Moving flake input from `nixos-24.05` to `nixos-unstable`
2. Updating **all custom package versions and hashes**
3. Removing ESP8266 support
4. Resolving breakages introduced by the upgrade

In-scope files include:

- `flake.nix`
- `flake.lock`
- `overlay.nix`
- `pkgs/esp-idf/default.nix`
- `pkgs/esp-idf/python-packages.nix`
- `pkgs/llvm-xtensa-bin.nix`
- `pkgs/llvm-xtensa-lib.nix`
- `pkgs/rust-xtensa-bin.nix`
- `shells/*.nix` (especially `*-idf-rust.nix`, `esp8266-rtos-sdk.nix`)
- `tests/*.nix` (especially `build-esp8266-example.nix`)
- `README.md`
- ESP8266 package subtree under `pkgs/esp8266-rtos-sdk/`

---

## 2) Current state summary (baseline)

- Flake now tracks `nixpkgs/nixos-unstable` in `flake.nix` and `flake.lock` is updated.
- `pkgs/esp-idf` in-tree is pinned at `v5.5.2` (see `pkgs/esp-idf/default.nix`); the repo and tooling were reworked to use a local tool derivation pipeline.
- Python package pins in `pkgs/esp-idf/python-packages.nix` were refreshed to a v5.5-era constraint set (many packages updated), not yet aligned to the v6.0 targets in this plan.
- Xtensa LLVM and Rust binary packages remain at their previous versions (see `pkgs/llvm-xtensa-bin.nix`, `pkgs/llvm-xtensa-lib.nix`, `pkgs/rust-xtensa-bin.nix`) and need Phase E bumps.
- Rust dev shells still export `ESP_IDF_VERSION=v4.4.1` (see `shells/*-idf-rust.nix`) and should be updated after ESP-IDF pins are finalized.
- ESP8266 support has been removed from public outputs, tests and overlays in recent commits (the removal commit exists on the upgrade branch).

---

## 3) Target versions to adopt

## 3.1 Core toolchain / framework targets

- **ESP-IDF**: `v6.0` (latest stable release)
- **Espressif LLVM**: `esp-21.1.3_20260304`
- **esp-rs Rust Xtensa toolchain**: `1.93.0.0`
- **nixpkgs flake input**: `nixos-unstable`

## 3.2 ESP-IDF Python package targets (from v6.0 constraints and latest compatible releases)

Use ESP-IDF v6.0 constraints as compatibility boundary, then pin latest within range:

- `idf-component-manager`: **3.0.0** (`~=3.0`)
- `esptool`: **5.2.0** (`~=5.2`)
- `esp-coredump`: **1.15.0** (`~=1.14`)
- `esp-idf-kconfig`: **3.6.0** (`>=3.2,<4.0`)
- `esp-idf-monitor`: **1.9.0** (`>=1.6.2,<2`)
- `esp-idf-size`: **2.1.0** (`>=2.0,<3.0`)
- `freertos-gdb`: **1.0.4** (`~=1.0`)

Also evaluate whether to add/override if nixpkgs is insufficient:

- `esp-idf-nvs-partition-gen`
- `esp-idf-diag`
- `pyclang`
- `construct`
- `rich`
- `psutil`
- `tree-sitter`, `tree-sitter-c`

---

## 4) Detailed execution plan

## Phase A - Branching and safety

1. Create a dedicated branch, e.g. `upgrade/nixos-unstable-espidf-v6`.
2. Snapshot baseline:
   - `git status`
   - `git diff`
3. Run baseline checks once to compare post-upgrade failures.

## Phase B - Move flake to unstable

1. Edit `flake.nix`:
   - change `inputs.nixpkgs.url` from `nixpkgs/nixos-24.05` to `nixpkgs/nixos-unstable`
2. Refresh lock:
   - `nix flake update nixpkgs` (or `nix flake update --update-input nixpkgs`)
3. Verify lock updated correctly in `flake.lock`.

## Phase C - Remove ESP8266 support

1. `overlay.nix`:
   - remove `gcc-xtensa-lx106-elf-bin` and `esp8266-rtos-sdk` overlay attrs
2. `flake.nix`:
   - remove `gcc-xtensa-lx106-elf-bin` and `esp8266-rtos-sdk` from `packages`
   - remove `esp8266-rtos-sdk` devShell
   - remove `build-esp8266-example` check merge
   - update description text from `ESP8266/ESP32` to `ESP32`
3. Remove obsolete ESP8266 files:
   - `shells/esp8266-rtos-sdk.nix`
   - `tests/build-esp8266-example.nix`
   - `pkgs/esp8266-rtos-sdk/` subtree
4. README cleanup:
   - remove/adjust ESP8266 support claims and examples if present.

## Phase D - Upgrade ESP-IDF package and compatibility pins

Phase D is complete through D3; ESP-IDF core overlays and Python package pins now aligned to v6.0; tree is stable and `esp-idf-full` builds succeed (with insecure Python workaround for ecdsa). Example/dev shell validation is next. Detailed log of completed work and next steps below:

- D0. Stabilize current tree (required before attempting v6 bumps):
  - [x] Run `nix flake show` and a short `nix eval` for a sample package (see Phase H gating checks) to ensure the flake evaluates.
  - [x] Address any immediate eval/runtime regressions caused by the python-package refresh or tools rewrite.

- D1. Bump ESP-IDF version in `pkgs/esp-idf/default.nix` (after D0):
  - [x] Change `rev` from current `v5.5.2` → target `v6.0`.
  - [x] Update `sha256` for GitHub source (submodules enabled).
- D2. Validate/update `toolsToInclude` against new ESP-IDF v6.0 `tools.json`:
  - [x] Confirm/include required tool names for each target (xtensa and riscv variants) according to v6 `tools.json`.
- D3. Reconcile Python dependencies (build & runtime):
  - [x] Refresh all pins to match ESP-IDF v6.0 `requirements.core.txt`.
  - [x] Ensure **every** requirement from v6.0 `requirements.core.txt` is present in `customPython` list in `default.nix` or provided by nixpkgs.
  - [x] Keep only needed overrides if newer versions in nixpkgs are compatible.
  - [x] Patch/test for correct build backend (pyproject vs setuptools) and native deps; add `format = "pyproject"` where required.
  - [x] Remove stale/obsolete patches introduced for older idf-component-manager/install paths.

(Phase E – binary bumps, and Phase F – shell/env, are still NOT started. Phase D must be correct before proceeding.)

## Phase E - Upgrade custom LLVM/Rust binaries

1. `pkgs/llvm-xtensa-bin.nix`
   - `version = "21.1.3_20260304"`
   - update `hash` for `clang-esp-...-x86_64-linux-gnu.tar.xz`
2. `pkgs/llvm-xtensa-lib.nix`
   - same version
   - update `hash` for `libs-clang-esp-...-x86_64-linux-gnu.tar.xz`
3. `pkgs/rust-xtensa-bin.nix`
   - `version = "1.93.0.0"`
   - update both fetches:
     - `rust-${version}-x86_64-unknown-linux-gnu.tar.xz`
     - `rust-src-${version}.tar.xz`
   - update `date` metadata to release date (for traceability).

## Phase F - Shell alignment and environment cleanup (completed)

1. `shells/esp32-idf-rust.nix`, `shells/esp32s2-idf-rust.nix`, `shells/esp32c3-idf-rust.nix`:
   - updated `ESP_IDF_VERSION` from `v4.4.1` to `v6.0` and committed the shell changes.
2. Verified `LIBCLANG_PATH` and `RUSTFLAGS` are exported in shells; left `RUSTFLAGS="--cfg espidf_time64"` in place (required by current esp-rs toolchain).
3. Performed a quick shell verification using `NIXPKGS_ALLOW_INSECURE=1` and `--impure` to allow evaluation of an insecure ecdsa package; this triggered wheel builds (e.g., `esp-idf-kconfig`, `esptool`) and toolchain derivations — wheel builds completed during verification.
   - Logs from the verification run are saved at: `/home/jaanonim/.local/share/opencode/tool-output/tool_d0c77a58e001N9VMC4AzVcaHtH`.
   - A missing Python runtime dependency (`pyparsing`) was added to `pkgs/esp-idf/python-packages.nix` (esp-idf-kconfig and affected packages) to resolve runtime-deps checks.

## Phase G - Resolve breakages (expected problem list)

Likely failure classes and fixes:

1. **Python package build failures** (pyproject migration, dependency names changed)
   - add `format = "pyproject"` where needed
   - add/adjust `nativeBuildInputs` (`setuptools`, `wheel`, `hatchling`, etc. as required)
2. **Missing runtime deps in custom Python env**
   - include new ESP-IDF v6 core requirements (`rich`, `construct`, etc.)
3. **Tool wrapping breakages**
   - verify wrapped binaries in `pkgs/esp-idf/tools.nix` still execute in FHS env
4. **Shell/runtime mismatch**
   - stale env vars or old assumptions in shell hooks
5. **Check derivation failures**
   - tighten/check target-specific builds in `tests/build-idf-examples.nix`.

## Phase H - Validation matrix (must pass before done)

Run in this order (add a lightweight eval gate before heavy builds):

1. `nix flake show` (quick verification the flake evaluates).
2. Lightweight eval gate: `nix eval .#packages.x86_64-linux.esp-idf-full.name` (or similar package attribute on your platform) to ensure package attrs evaluate.
3. `nix flake check -L` (once eval gate passes).
4. Build key packages individually (only after checks above):
   - `nix build .#esp-idf-full -L`
   - `nix build .#esp-idf-esp32 -L`
   - `nix build .#esp-idf-esp32c3 -L`
   - `nix build .#llvm-xtensa -L`
   - `nix build .#rust-xtensa -L`
5. Enter critical dev shells and verify envs:
   - `nix develop .#esp32-idf-rust -c env | grep ESP_IDF_VERSION`
   - same for s2/c3 shells
6. Optional smoke:
   - build `hello_world` from IDF examples for at least one Xtensa and one RISC-V target.

Known regressions / immediate TODOs (fast follow):

- update shell `ESP_IDF_VERSION` exports in `shells/*-idf-rust.nix` after D1/D3.

---

## 5) Hash update procedure (repeatable)

For each custom source update:

1. Set `hash = lib.fakeHash` or temporary wrong hash.
2. Run `nix build` for that derivation.
3. Copy reported "got" hash into file.
4. Rebuild to confirm.

For Python `fetchPypi` / `fetchFromGitHub` updates:

- same fake-hash cycle package by package to avoid ambiguity.

---

## 6) Commit strategy

Suggested commits (small and reviewable):

1. `flake: switch nixpkgs input to nixos-unstable`
2. `drop esp8266 support from overlay, shells, tests, packages`
3. `esp-idf: bump to v6.0 and refresh python package pins`
4. `toolchains: bump llvm-xtensa and rust-xtensa binaries`
5. `shells/docs: align ESP_IDF_VERSION and README`

---

## 7) Risk notes

- ESP-IDF 6.0 is a major release with breaking changes; examples/build logic may need minor adjustments.
- Python ecosystem drift is the highest-risk area (build backend changes).
- Removing ESP8266 changes public surface; document this clearly in README/changelog.

---

## 8) Definition of done

Done means all of the following are true:

1. `flake.nix` tracks `nixos-unstable`
2. All custom package pins have updated versions and valid hashes
3. ESP8266 support is fully removed from exposed outputs and checks
4. `nix flake check -L` passes
5. At least one Rust-capable shell and one IDF example build succeed
6. README reflects new support matrix and versions
