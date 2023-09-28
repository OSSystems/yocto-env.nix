{
  description = "Yocto Project - Development Environment";

  inputs.nixpkgs.url = "nixpkgs/23.11";
  inputs.nixpkgs_19_09 = { url = "nixpkgs/19.09"; flake = false; };

  outputs = { self, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import inputs.nixpkgs { inherit system; };
          pkgs_19_09 = import inputs.nixpkgs_19_09 { inherit system; };
          mkYoctoEnv =
            { pkgs
            , pkgsForYocto ? pkgs
            , withPython2 ? false
            , usesInclusiveLanguage ? true
            }: import ./yocto-env.nix {
              inherit
                pkgs
                pkgsForYocto
                withPython2
                usesInclusiveLanguage
                ;
            };
        in
        {
          default = mkYoctoEnv { inherit pkgs; }; # Current master

          scarthgap = self.devShells.${system}.default; # 5.0 -	April 2024

          nanbield = self.devShells.${system}.scarthgap; # 4.3 - October 2023

          mickledore = self.devShells.${system}.nanbield; # 4.2 -May 2023

          langdale = self.devShells.${system}.mickledore; # 4.1 - October 2022

          kirkstone = self.devShells.${system}.langdale; # 4.0 - May 2022

          honister = self.devShells.${system}.kirkstone; # 3.4 - October 2021

          hardknott = self.devShells.${system}.honister; # 3.3 - April 2021

          gatesgarth = self.devShells.${system}.hardknott; # 3.2 - Oct 2020

          dunfell = self.devShells.${system}.gatesgarth; # 3.1 - April 2020

          zeus = self.devShells.${system}.dunfell; # 3.0 - October 2019

          warrior = mkYoctoEnv {
            # 2.7 - April 2019
            inherit pkgs; pkgsForYocto = pkgs_19_09;
            withPython2 = true;
          };

          thud = self.devShells.${system}.warrior; # 2.6 - Nov 2018

          sumo = self.devShells.${system}.thud; # 2.5 - April 2018

          rocko = self.devShells.${system}.sumo; # 2.4 - Oct 2017
        });
    };
}
