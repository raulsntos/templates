{
  description = "A simple C# package";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
            # See https://nixos.org/manual/nixpkgs/stable/#dotnet
            # for more information.
            csharp-hello = pkgs.buildDotnetModule {
              pname = "csharp-hello";
              version = "1.0.0.0";
              # In 'nix develop', we don't need a copy of the source tree
              # in the Nix store.
              src = ./.;

              projectFile = "./Hello.csproj";
              nugetDeps = ./deps.nix;

              dotnet-sdk = pkgs.dotnet-sdk;
              dotnet-runtime = pkgs.dotnet-runtime;
            };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.csharp-hello);
    };
}
