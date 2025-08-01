{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix.url = "github:NixOS/nix";
    home-manager.url = "github:rycee/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nofib.url = "git+https://gitlab.haskell.org/ghc/nofib?ref=wip/input-utf8";
    nofib.flake = false;
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    envfs.url = "github:Mic92/envfs";
    envfs.inputs.nixpkgs.follows = "nixpkgs";
    wakatime-ls.url = "github:mrnossiom/wakatime-ls";
    wakatime-ls.inputs.nixpkgs.follows = "nixpkgs";
    dagger.url = "github:dagger/nix";
    dagger.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Taken from https://github.com/davidtwco/veritas/blob/master/flake.nix
  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      envfs,
      ...
    }@inputs:
    with inputs.nixpkgs.lib;
    let
      #username = "daniel";
      forEachSystem = genAttrs [ "x86_64-linux" ];
      pkgsBySystem = forEachSystem (
        system:
        import inputs.nixpkgs {
          inherit system;
          config = import ./nixpkgs/config.nix;
          # Overlays consumed by the home-manager/NixOS configuration.
          overlays = [
            (import ./nixpkgs/overlays/evince.nix)
            ((import ./nixpkgs/overlays/wakatime-ls.nix) inputs.wakatime-ls system)
            ((import ./nixpkgs/overlays/dagger.nix) inputs.dagger system)
          ];
        }
      );

      unstableBySystem = forEachSystem (
        system:
        import inputs.unstable {
          inherit system;
          config = import ./nixpkgs/config.nix;
        }
      );

      # mkHomeManagerConfiguration could just be
      #    nameValuePair hostname config
      # But the nix/registry.json settings need access to inputs.
      # Since the other stuff belongs with those settings, it makes
      # sense to have this function. Although we could have solved this through passing inputs as extraSpecialArgs.
      mkHomeManagerConfiguration =
        hostname:
        { system, config }:
        nameValuePair hostname (
          { ... }:
          {
            imports = [
              inputs.nix-doom-emacs.hmModule
              (import config)
            ];

            # Use the same Nix configuration throughout the system.
            # We really need to set ~/.config/nixpkgs/config.nix as well as import
            # it in home-manager's nixpkgs.config; see the manpage.
            xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs/config.nix;
            nixpkgs.config = import ./nixpkgs/config.nix;
            xdg.configFile."nix/nix.conf".source = ./nix/nix.conf;

            # Re-expose self, nixpkgs and unsable as flakes. For use in nix-search, for example
            nix = {
              #settings = {
              #  experimental-features = [ "nix-command" "flakes" ];
              #};
              # Re-expose self, nixpkgs and unstable as flakes.
              registry = {
                self.flake = inputs.self;
                nixpkgs = {
                  from = {
                    id = "nixpkgs";
                    type = "indirect";
                  };
                  flake = inputs.nixpkgs;
                };
                unstable = {
                  from = {
                    id = "unstable";
                    type = "indirect";
                  };
                  flake = inputs.unstable;
                };
                wakatime-ls = {
                  from = {
                    id = "wakatime-ls";
                    type = "indirect";
                  };
                  flake = inputs.wakatime-ls;
                };
              };
            };
          }
        );

      mkNixOsConfiguration =
        hostname:
        {
          system,
          config,
          username,
        }:
        nameValuePair hostname (nixosSystem {
          inherit system;
          modules = [
            nixos-wsl.nixosModules.wsl
            envfs.nixosModules.envfs
            (
              {
                inputs,
                hostname,
                pkgs,
                ...
              }:
              {
                # Set the hostname to the name of the configuration being applied (since the
                # configuration being applied is determined by the hostname).
                networking.hostName = hostname;

                # Use the nixpkgs from the flake.
                nixpkgs.pkgs = pkgsBySystem.${system};

                # For compatibility with nix-shell, nix-build, etc.
                # See also the setting of NIX_PATH in the home-manager host config
                environment.etc.nixpkgs.source = inputs.nixpkgs;
                environment.etc.unstable.source = inputs.unstable;
                nix.nixPath = [
                  "nixpkgs=/etc/nixpkgs"
                  "unstable=/etc/unstable"
                ];

                nix = {
                  # Don't rely on the configuration to enable a flake-compatible version of Nix.
                  # package = pkgs.nixFlakes;
                  extraOptions = "experimental-features = nix-command flakes";
                  # Re-expose self, nixpkgs and unstable as flakes.
                  registry = {
                    self.flake = inputs.self;
                    nixpkgs = {
                      from = {
                        id = "nixpkgs";
                        type = "indirect";
                      };
                      flake = inputs.nixpkgs;
                    };
                    unstable = {
                      from = {
                        id = "unstable";
                        type = "indirect";
                      };
                      flake = inputs.unstable;
                    };
                  };
                  settings = {
                    auto-optimise-store = true;
                  };
                };
              }
            )
            (import config)
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${username} = homeManagerConfigurations."${hostname}";
              home-manager.extraSpecialArgs = {
                inherit hostname inputs;
                unstable = unstableBySystem."${system}";
              };
            }
          ];
          specialArgs = {
            inherit hostname inputs;
            unstable = unstableBySystem."${system}";
          };
        });

      mkHomeManagerHostConfiguration =
        hostname:
        { system, username }: # The original template is much more flexible here
        # home-manager switch --flake tries `<flake-uri>#homeConfigurations."${username}@${hostname}"`
        nameValuePair "${username}@${hostname}" (
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsBySystem."${system}";
            modules = [
              homeManagerConfigurations."${hostname}"
              (
                { ... }:
                {
                  # Only username/hostname dependent configuration here
                  home = {
                    homeDirectory = "/home/${username}";
                    username = "${username}";
                  };
                  # For compatibility with nix-shell, nix-build, etc.
                  # See also the setting of NIX_PATH in the NixOS host config
                  home.file.".nixpkgs/stable".source = inputs.nixpkgs;
                  home.file.".nixpkgs/unstable".source = inputs.unstable;
                  systemd.user.sessionVariables."NIX_PATH" =
                    mkForce "nixpkgs=$HOME/.nixpkgs/stable:unstable=$HOME/.nixpkgs/unstable\${NIX_PATH:+:}$NIX_PATH";
                }
              )
            ];
            extraSpecialArgs = {
              inherit hostname inputs;
              unstable = unstableBySystem."${system}";
              kitty-fix = import inputs.kitty-fix { inherit system; };
            };
          }
        );

      # Attribute set of hostnames to home-manager modules with the entire configuration for
      # that host - consumed by the home-manager NixOS module for that host (if it exists)
      # or by `mkHomeManagerHostConfiguration` for home-manager-only hosts.
      homeManagerConfigurations = mapAttrs' mkHomeManagerConfiguration {
        DN-Laptop = {
          system = "x86_64-linux";
          config = ./home/private.nix;
        };
        nixos-lt = {
          system = "x86_64-linux";
          config = ./home/private.nix;
        };
        "i44pc6.ppd.ipd.kit.edu" = {
          system = "x86_64-linux";
          config = ./home/work.nix;
        };
        "i44pc19" = {
          system = "x86_64-linux";
          config = ./home/work.nix;
        };
        "i44pc30" = {
          system = "x86_64-linux";
          config = ./home/work.nix;
        };
        Daniel-PC = {
          system = "x86_64-linux";
          config = ./home/wsl.nix;
        };
      };

      homeManagerHostConfigurations = mapAttrs' mkHomeManagerHostConfiguration {
        "i44pc6.ppd.ipd.kit.edu" = {
          system = "x86_64-linux";
          username = "sgraf-local";
        };
        "i44pc19" = {
          system = "x86_64-linux";
          username = "sgraf-local";
        };
        "i44pc30" = {
          system = "x86_64-linux";
          username = "sgraf-local";
        };
        # Daniel-PC = { system = "x86_64-linux"; username = "nixos"; };
      };

      # Attribute set of hostnames to evaluated NixOS configurations. Consumed by `nixos-rebuild`
      # on those hosts.
      nixosHostConfigurations = mapAttrs' mkNixOsConfiguration {
        DN-Laptop = {
          system = "x86_64-linux";
          config = ./nixos/framework.nix;
          username = "daniel";
        };
        Daniel-PC = {
          system = "x86_64-linux";
          config = ./nixos/wsl.nix;
          username = "nixos";
        };
      };

    in
    {
      homeConfigurations = homeManagerHostConfigurations;
      nixosConfigurations = nixosHostConfigurations;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
