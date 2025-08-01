{ pkgs, lib, ... }:

{
  imports = [ ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "elixir"
      "make"
      "dart"
      "latex"
      "java"
      "log"
      "ltex"
      "git-firefly"
      "dockerfile"
      "wakatime"
      "proto"
    ];

    ## everything inside of these brackets are Zed options.
    userSettings = {
      assistant = {
        enabled = false;
        version = "2";
        default_open_ai_model = null;
        ### PROVIDER OPTIONS
        ### zed.dev models { claude-3-5-sonnet-latest } requires github connected
        ### anthropic models { claude-3-5-sonnet-latest claude-3-haiku-latest claude-3-opus-latest  } requires API_KEY
        ### copilot_chat models { gpt-4o gpt-4 gpt-3.5-turbo o1-preview } requires github connected
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
        #                inline_alternatives = [
        #                    {
        #                        provider = "copilot_chat";
        #                        model = "gpt-3.5-turbo";
        #                    }
        #                ];
      };
      hour_format = "hour24";
      auto_update = false;
      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        detect_venv = {
          on = {
            directories = [
              ".env"
              "env"
              ".venv"
              "venv"
            ];
            activate_script = "default";
          };
        };
        env = {
          TERM = "alacritty";
        };
        font_family = "FiraCode Nerd Font";
        font_features = null;
        font_size = null;
        line_height = "comfortable";
        option_as_meta = false;
        button = false;
        shell = "system";
        #{
        #                    program = "zsh";
        #};
        toolbar = {
          title = true;
        };
        working_directory = "current_project_directory";
      };

      languages = {
        YAML = {
          formatter = "language_server";
        };
        Nix = {
          language_servers = [
            "nil"
            "!nixd"
          ];
          formatter = {
            external = {
              command = "nixfmt";
            };
          };
        };
      };

      lsp = {
        dart = {
          binary.path_lookup = true;
        };
        package-version-server = {
          binary.path_lookup = true;
        };
        wakatime-ls = {
          binary.path_lookup = true;
        };
        wakatime = {
          binary.path_lookup = true;
        };
        yaml-language-server = {
          binary.path_lookup = true;
        };
        json-language-server = {
          binary.path_lookup = true;
        };
        gopls = {
          binary.path_lookup = true;
        };
        rust-analyzer = {
          binary.path_lookup = true;
        };
        nil = {
          binary.path_lookup = true;
          settings = {
            nix.flake.autoArchive = true;
          };
        };
        elixir-ls = {
          binary.path_lookup = true;
          settings = {
            dialyzerEnabled = true;
          };
        };
        texlab = {
          binary.path_lookup = true;
          settings = {
            texlab = {
              latexindent = {
                modifyLineBreaks = true;
              };
              build = {
                onSave = true;
                forwardSearchAfter = true;
                executable = "latexmk";
                args = [
                  "-pdf"
                  "-bibtex"
                  "-interaction=nonstopmode"
                  "-synctex=1"
                  "%f"
                ];
              };
            };
          };
        };
        ltex = {
          binary.path_lookup = true;
          settings = {
            ltex = {
              language = "en-US";
            };
          };
        };
      };

      soft_wrap = "editor_width";
      vim_mode = false;
      tab_size = 2;
      # tell zed to use direnv and direnv can use a flake.nix enviroment.
      load_direnv = "shell_hook";
      base_keymap = "JetBrains";
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      show_whitespaces = "all";
      ui_font_size = 20;
      buffer_font_size = 16;
      buffer_line_height = "comfortable";
      autosave = "on_focus_change";
      restore_on_startup = "last_session";
    };
  };
}
