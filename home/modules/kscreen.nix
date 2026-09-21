# Mode-switching aliases for xenon's desk (2x24in) vs. TV (couch/gaming)
# monitor setups. KWin itself persists
# per-output layouts keyed by connected-output topology, so most of the time
# no manual switching is needed — this is only for when you want to pick a
# mode while everything is plugged in simultaneously.
#
# NOT YET WIRED IN: fill in the real connector names (read via
# `kscreen-doctor -o` on the actual hardware, e.g. HDMI-A-1/DP-1) and import
# this from home/private.nix.

{ pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.kscreen ]; # provides kscreen-doctor

  programs.zsh.shellAliases = {
    desk-mode = "kscreen-doctor output.<TV>.disable output.<Mon1>.enable output.<Mon2>.enable";
    tv-mode = "kscreen-doctor output.<Mon1>.disable output.<Mon2>.disable output.<TV>.enable";
  };
}
