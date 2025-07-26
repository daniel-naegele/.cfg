{
  allowUnfree = true;
  allowBroken = true;
  packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };
  permittedInsecurePackages = [
    "fluffychat-linux-1.27.0"
    "olm-3.2.16"
  ];
}
