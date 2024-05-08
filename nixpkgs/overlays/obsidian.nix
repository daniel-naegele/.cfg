self: super:

{
  obsidian = super.obsidian.overrideAttrs (old: {
    version = "1.5.12";  
  });
}
