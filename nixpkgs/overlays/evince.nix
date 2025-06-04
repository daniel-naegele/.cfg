self: super:

{
  sushi = super.sushi.overrideAttrs (oldAttrs: rec {
    preConfigure = ''
      export PKG_CONFIG_PATH="${self.evince.dev}/lib/pkgconfig:${super.libepoxy.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
      echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
      pkg-config --modversion evince-document-3.0 || echo "NOT FOUND"
    '';

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      self.evince.dev
      super.libepoxy.dev
    ];
  });

  evince = super.evince.overrideAttrs (oldAttrs: rec {
    pname = "evince";
    version = "unstable-2025-06-04"; # Optional: indicate this is not a release

    # Replace with the actual commit hash
    src = super.fetchgit {
      url = "https://github.com/daniel-naegele/evince-fork.git";
      rev = "08e73bae9063b2e8a4df3cae81ada009ce7f3bf5";
      sha256 = "sha256-rl5L+jnz6fjD5YmIWw4yw3/3cgU8f+0HDVyBo+rgq1w="; # Run once with a fake sha256 and let Nix tell you the real one.
    };

    outputs = [
      "out"
      "dev"
    ];

    postFixup = '''';

    postInstall = ''
      # Ensure .pc files go to $dev
      mkdir -p $dev/lib/pkgconfig
      if [ -d $out/lib/pkgconfig ]; then
        mv $out/lib/pkgconfig/*.pc $dev/lib/pkgconfig/
      fi
    '';

    # You may need to patch meson flags or dependencies depending on commit
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ super.pkg-config ];
    buildInputs = oldAttrs.buildInputs ++ [
      super.gtk3
      super.poppler
      super.exempi
      super.cmake
    ];

    # Optional: explicitly enable meson if missing
    mesonBuild = true;
  });
}
