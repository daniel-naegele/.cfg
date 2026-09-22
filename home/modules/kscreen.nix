# Mode-switching aliases for xenon's desk (2x24in) vs. TV (couch/gaming)
# monitor setups. KWin itself persists per-output layouts keyed by
# connected-output topology, so most of the time no manual switching is
# needed — this is only for when you want to pick a mode while everything
# is plugged in simultaneously.
#
# Monitor connector names confirmed via `kscreen-doctor -o`: DP-1 and
# HDMI-A-1 are the two 24in desk monitors. The TV's connector name is still
# a placeholder (<TV>) — it wasn't connected when this was written. Plug it
# in, run `kscreen-doctor -o` to find its real name, and replace <TV> below.

{ pkgs, ... }:
let
  tv = "HDMI-A-2";
  mon1 = "HDMI-A-1";
  mon2 = "DP-1";
in
{
  home.packages = [ pkgs.kdePackages.kscreen ]; # provides kscreen-doctor

  programs.zsh.shellAliases = {
    desk-mode = "kscreen-doctor output.${tv}.disable output.${mon1}.enable output.${mon2}.enable";
    tv-mode = "kscreen-doctor output.${mon1}.disable output.${mon2}.disable output.${tv}.enable";
  };
}
