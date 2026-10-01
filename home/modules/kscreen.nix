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

  # kscreen-doctor is a Qt/Wayland app — it needs WAYLAND_DISPLAY,
  # XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS from the graphical
  # session. A plain SSH/tty shell has none of those, so pull them from
  # `systemctl --user` before dispatching, instead of failing with a Qt
  # xcb error.
  kscreen-doctor-session = pkgs.writeShellScript "kscreen-doctor-session" ''
    if [ -z "$WAYLAND_DISPLAY" ]; then
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export $(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS)=')
    fi
    exec kscreen-doctor "$@"
  '';
in
{
  home.packages = [ pkgs.kdePackages.kscreen ]; # provides kscreen-doctor

  programs.zsh.shellAliases = {
    desk-mode = "${kscreen-doctor-session} output.${mon1}.enable output.${mon2}.enable output.${tv}.disable";
    tv-mode = "${kscreen-doctor-session} output.${tv}.enable output.${mon1}.disable output.${mon2}.disable";
  };
}
