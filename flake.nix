{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flakes-part.url = "github:hercules-ci/flake-parts";

        treefmt-nix.url = "github:numtide/treefmt-nix";
    };

    outputs = inputs@{flakes-part, ... }:
        flakes-part.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-darwin" ];
            imports = [
                inputs.treefmt-nix.flakeModule
            ];
            perSystem = {pkgs, config, ...}:
                let
                    cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
                    nonRustDeps = [ pkgs.libiconv ];
                    rust-toolchain = pkgs.symlinkJoin {
                        name = "rust-toolchain";
                        paths = [ pkgs.rustc pkgs.cargo pkgs.cargo-watch pkgs.rust-analyzer pkgs.rustPlatform.rustcSrc ];
                    };
                in {
                   packages.default = pkgs.rustPlatform.buildRustPackage {
                        inherit (cargoToml.package) name version;
                        src = ./.;
                        cargoLock.lockFile = ./Cargo.lock;
                    };

                    devShells.default = pkgs.mkShell {
                        # inputsFrom = [
                        #     config.treefmt.build.devShell
                        # ];
                        shellHook = ''
                            # For rust-analyzer 'hover' tooltips to work.
                            export RUST_SRC_PATH=${pkgs.rustPlatform.rustLibSrc}

                            echo
                            echo "Run 'just <recipe>' to get started"
                            just
                        '';
                        buildInputs = nonRustDeps;
                        nativeBuildInputs = [
                            rust-toolchain
                        ];
                        RUST_BACKTRACE = 1;
                    };

                    treefmt.config = {
                        projectRootFile = "flake.nix";
                        programs = {
                            nixpkgs-fmt.enable = true;
                            rustfmt.enable = true;
                        };
                    };
                };

        };
}