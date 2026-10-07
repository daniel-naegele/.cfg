{
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  home.packages = [ pkgs.wakatime-cli ];

  # api_key_vault_cmd keeps the key out of the nix store
  home.file.".wakatime.cfg".text = lib.generators.toINI { } {
    settings = {
      api_key_vault_cmd = "${pkgs.coreutils}/bin/cat ${osConfig.sops.secrets.wakatime_api_key.path}";
      api_url = "https://time.naegele.dev/api/v1/users/current/heartbeats.bulk";
    };
  };
}
