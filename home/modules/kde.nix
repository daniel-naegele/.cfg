{
  pkgs,
  config,
  ...
}:

let
  tailscale = "${pkgs.tailscale}/bin/tailscale";

  toggleVpn = pkgs.writeShellScript "toggle-vpn" ''
    if [[ -n $(${tailscale} status | grep "Tailscale is stopped") ]]; then
      ${tailscale} down
    else
      ${tailscale} up
    fi
  '';
in
{
  home.packages = with pkgs; [
    # Toggle-style replacement for the GNOME caffeine extension: prevents
    # sleep/idle while a marker process is running, kills it to re-allow sleep.
    (writeShellScriptBin "caffeine" ''
      pidfile="''${XDG_RUNTIME_DIR:-/tmp}/caffeine.pid"
      if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        kill "$(cat "$pidfile")"
        rm -f "$pidfile"
        echo "caffeine off"
      else
        ${systemd}/bin/systemd-inhibit --what=sleep:idle --why=caffeine sleep infinity &
        echo $! > "$pidfile"
        echo "caffeine on"
      fi
    '')
  ];

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  programs.plasma = {
    enable = true;

    session.sessionRestore.restoreOpenApplicationsOnLogin = "onLastLogout";

    workspace = {
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";
      theme = "breeze-dark";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
    };

    input.touchpads = [
      {
        name = "PIXA3854:00 093A:0274 Touchpad";
        vendorId = "093a";
        productId = "0274";
        naturalScroll = true;
        tapToClick = true;
      }
    ];

    configFile.kwinrc.TabBox.LayoutName = "org.kde.breeze.desktop";

    shortcuts = {
      ksmserver."Lock Session" = "Meta+L";
      kwin = {
        "Window Close" = [
          "Meta+Q"
          "Alt+F4"
        ];
        "Window Minimize" = "Meta+Comma";
        # GNOME's separate maximize/unmaximize/toggle-maximized actions all
        # collapse into KWin's single maximize-toggle action.
        "Window Maximize" = [
          "Meta+Up"
          "Meta+M"
        ];
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch One Desktop Up" = [
          "Meta+Ctrl+Up"
          "Meta+Ctrl+K"
        ];
        "Switch One Desktop Down" = [
          "Meta+Ctrl+Down"
          "Meta+Ctrl+J"
        ];
        "Walk Through Windows" = "Alt+Tab";
        "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
      };
    };

    hotkeys.commands = {
      toggle-vpn = {
        name = "Toggle VPN";
        key = "F12";
        command = "${toggleVpn}";
      };
      launch-terminal = {
        name = "Launch terminal";
        key = "Meta+T";
        # Unlike the GNOME version (dconf.nix's old gnome-cwd trick via the
        # window-calls-extended extension), this always opens at $HOME - KWin
        # has no built-in equivalent for "cwd of the focused window".
        command = "${config.programs.kitty.package}/bin/kitty";
      };
      launch-home = {
        name = "Open home folder";
        key = "Meta+F";
        command = "dolphin";
      };
      launch-email = {
        name = "Launch email client";
        key = "Meta+E";
        command = "${pkgs.xdg-utils}/bin/xdg-open mailto:";
      };
      launch-browser = {
        name = "Launch web browser";
        key = "Meta+B";
        command = "${config.programs.firefox.package}/bin/firefox";
      };
    };
  };

  # Not translated from dconf.nix - no confidently-correct KDE/KWin
  # equivalent found, revisit via System Settings if still wanted:
  # - workspaces-only-on-primary = false (KWin virtual desktops already
  #   span all monitors, so this may be moot)
  # - input-sources show-all-sources (keyboard layout indicator)
  # - event-sounds = false (system/notification sound mute)
  # - toggle-message-tray shortcut (no confirmed plasmashell action name)
}
