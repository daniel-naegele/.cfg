{ pkgs, lib, config, ... }:

let
  mkShortcuts = settings:
    let
      inherit (builtins) length head tail listToAttrs genList;
      range = a: b: if a < b then [a] ++ range (a+1) b else [];
      globalPath = "org/gnome/settings-daemon/plugins/media-keys";
      path = "${globalPath}/custom-keybindings";
      mkPath = id: "${path}/custom${toString id}";
      isEmpty = list: length list == 0;
      checkSettings = { name, command, binding }@this: this;
      aux = i: list:
        if isEmpty list then [] else
          let
            hd = head list;
            tl = tail list;
            name = mkPath i;
          in
            aux (i+1) tl ++ [ {
              name = mkPath i;
              value = checkSettings hd;
            } ];
      settingsList = (aux 0 settings);
    in
      listToAttrs (settingsList ++ [
        {
          name = globalPath;
          value = genList (i: "/${mkPath i}/") (length settingsList);
        }
      ]);

  gnomeCwd = pkgs.writeShellScriptBin "gnome-cwd" ''
    # Install and activate https://extensions.gnome.org/extension/4974/window-calls-extended/
    # to use this script
    #
    # Inspired by https://www.reddit.com/r/swaywm/comments/ayedi1/comment/ei7i1dl/
    #
    pid=$(${pkgs.glib}/bin/gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/WindowsExt --method org.gnome.Shell.Extensions.WindowsExt.FocusPID | sed -E "s/\\('(.*)',\\)/\\1/g")
    ppid=$(${pkgs.procps}/bin/pgrep --newest --parent $pid)
    readlink /proc/$ppid/cwd || echo $HOME
  '';

in

{
  # Needs the following in the system config:
  # services.dbus.packages = [ pkgs.dconf ];

  imports = [ ];

  home.packages = with pkgs; [
    dconf
  ];

  dconf.settings =
    (let
      nmcli = "${pkgs.networkmanager}/bin/nmcli";
    in
      mkShortcuts [
        {
          name = "Toggle VPN";
          #binding = "XF86AudioMedia"; # can't catch this key for some reason
          binding = "F12";
          command = "sh -c 'if [[ -n $(${nmcli} con show kit | grep \"VPN connected\") ]]; then ${nmcli} con down kit; else ${nmcli} con up kit; fi'";
        }
        {
          name = "Launch terminal here";
          #binding = "XF86AudioMedia"; # can't catch this key for some reason
          binding = "<super>t";
          command = "${config.programs.kitty.package}/bin/kitty --working-directory $(${gnomeCwd}/bin/gnome-cwd)";
        }
      ])
    //
    ({
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
    })
    //
    ({
      "org/gnome/desktop/input-sources" = {
        show-all-sources = true;
      };
    })
    //
    ({
      "org/gnome/desktop/sound" = {
        event-sounds = false;
      };
    })
    //
    ({
      # pop-shell stuff
      #
      #"org/gnome/shell" = {
      #  disable-user-extensions = false;
      #  enabled-extensions = [
      #    "pop-shell@system76.com"
      #  ];
      #};
      # disable incompatible shortcuts
      "org/gnome/mutter/wayland/keybindings" = {
        # restore the keyboard shortcuts: disable <super>escape
        restore-shortcuts = [];
      };
      "org/gnome/desktop/wm/keybindings" = {
        # hide window: disable <super>h
        minimize = [ "<super>comma" ];
        # switch to workspace left: disable <super>left
        switch-to-workspace-left = [ "<primary><super>left" ];
        # switch to workspace right: disable <super>right
        switch-to-workspace-right = [ "<primary><super>right" ];
        # maximize window: disable <super>up
        maximize = [ "<super>up" ];
        # restore window: disable <super>down
        unmaximize = [ "<super>down" ];
        # move to monitor up: disable <super><shift>up
        move-to-monitor-up = [];
        # move to monitor down: disable <super><shift>down
        move-to-monitor-down = [];
        # super + direction keys, move window left and right monitors, or up and down workspaces
        # move window one monitor to the left
        move-to-monitor-left = [];
        # move window one workspace down
        move-to-workspace-down = [];
        # move window one workspace up
        move-to-workspace-up = [];
        # move window one monitor to the right
        move-to-monitor-right = [];
        # super + ctrl + direction keys, change workspaces, move focus between monitors
        # move to workspace below
        switch-to-workspace-down = [ "<primary><super>down" "<primary><super>j" ];
        # move to workspace above
        switch-to-workspace-up = [ "<primary><super>up" "<primary><super>k" ];
        # toggle maximization state
        toggle-maximized = [ "<super>m" ];
        # close window
        close = [ "<super>q" "<alt>f4" ];
        # Instead of switch-applications
        switch-windows = [ "<alt>Tab" ];
        switch-windows-backwards = [ "<alt><shift>Tab" ];
      };
      "org/gnome/shell/keybindings" = {
        open-application-menu = [];
        # toggle message tray: disable <super>m
        toggle-message-tray = [ "<super>v" ];
        # show the activities overview: disable <super>s
        toggle-overview = [];
      };
      "org/gnome/mutter/keybindings" = {
        # do not disable tiling to left / right of screen
        # toggle-tiled-left = [];
        # toggle-tiled-right = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        # lock screen
        screensaver = [ "<super>l" ];
        # home folder
        home = [ "<super>f" ];
        # launch email client
        email = [ "<super>e" ];
        # launch web browser
        www = [ "<super>b" ];
        # launch terminal
        # Doesn't work
        #terminal = [ "<super>t" ];
        # rotate video lock
        rotate-video-lock-static = [];
      };
      "org/gnome/mutter" = {
        workspaces-only-on-primary = false;
        experimental-features = [ "scale-monitor-framebuffer" ];
      };

      "org/gnome/shell/window-switcher".current-workspace-only = false;
    });
}
