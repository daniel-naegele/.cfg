self: super: {
  texlive = super.texlive // {
    combined = super.texlive.combined // {
      scheme-full =
        (import
          (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/e13831335ff7f0e85f16e8354b2da0edd99af4e6.tar.gz";
            sha256 = "07040f5pmqnc2fp5yrcywl2l5krmhr9rz7y3i9hgsqjkx660sgm6";
          })
          {
            inherit (super) system;
            config = { };
          }
        ).texlive.combined.scheme-full;
    };
  };
}
