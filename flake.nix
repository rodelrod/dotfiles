{
  description = "Cross-platform Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, nix-darwin, ... }:
    let
      # macOS system configuration (nix-darwin)
      mkDarwinSystem = { system, username, homeDirectory, hostConfigModule, extraDarwinModules ? [ ] }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./darwin/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${username} = {
                imports = [
                  ./home/home.nix
                  hostConfigModule
                ];
                home.username = username;
                home.homeDirectory = homeDirectory;
              };
            }
          ] ++ extraDarwinModules;
        };

      # Linux user configuration (Home Manager only)
      mkLinuxSystem = { system, username, homeDirectory, hostConfigModule, cudaSupportIfApplies }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { 
            inherit system; 
            config = cudaSupportIfApplies // { allowUnfree = true; };
          };
          modules = [
            ./home/home.nix
            hostConfigModule
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };

    in {
      # macOS system configuration
      darwinConfigurations = {
        kubrick = mkDarwinSystem {
          system = "aarch64-darwin";
          username = "rodelrod";
          homeDirectory = "/Users/rodelrod";
          hostConfigModule = ./home/darwin.nix;
          extraDarwinModules = [
            # needed in kubrick because the first time nix was installed, it used old default instead of 3000
            { ids.gids.nixbld = 350; }    
          ];
        };
      };

      # Linux user configurations
      homeConfigurations = {
        xenakis = mkLinuxSystem {
          system = "x86_64-linux";
          username = "rodelrod";
          homeDirectory = "/home/rodelrod";
          hostConfigModule = ./home/linux.nix;
          cudaSupportIfApplies = { cudaSupport = true; };
        };
        ramiro = mkLinuxSystem {
          system = "x86_64-linux";
          username = "ramiro";
          homeDirectory = "/home/ramiro";
          hostConfigModule = ./home/linux.nix;
          cudaSupportIfApplies = { cudaSupport = false; };
        };
      };
    };
}
