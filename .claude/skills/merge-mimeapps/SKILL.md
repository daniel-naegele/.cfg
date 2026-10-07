---
name: merge-mimeapps
description: Fix a failed home-manager activation caused by ~/.config/mimeapps.list (e.g. "Existing file '.../mimeapps.list.backup' would be clobbered"). Diffs the files apps wrote at runtime against xdg.mimeApps in home/private.nix, merges new handlers into the nix definition, and clears the stale files so `switch` works again.
---

# Merge runtime mimeapps.list changes into home-manager

Apps (KDE, JetBrains, Bitwarden, Claude Code, ...) replace the home-manager symlink at `~/.config/mimeapps.list` with a regular file when they register a handler. Home-manager moves it to `mimeapps.list.backup` on the next switch; the second time it happens, the backup already exists and activation fails.

## Steps

1. Read every runtime copy that exists: `~/.config/mimeapps.list` (if it is a regular file, not a symlink into `/nix/store`) and `~/.config/mimeapps.list.backup`.

2. Build what home-manager currently generates, to diff against:
   ```bash
   nix build --no-link --print-out-paths \
     .#nixosConfigurations.$(hostname).config.home-manager.users.daniel.xdg.configFile.\"mimeapps.list\".source | xargs cat
   ```

3. Collect entries from `[Default Applications]` and `[Added Associations]` of the runtime files that are missing or different in the generated file. Entries under `[Added Associations]` only matter if no default exists for that mime type; prefer adding them as defaults.

4. For each new handler, check the `.desktop` file actually exists:
   ```bash
   ls /etc/profiles/per-user/daniel/share/applications/ /run/current-system/sw/share/applications/ ~/.local/share/applications/
   ```
   If the referenced name is stale (e.g. `Termius.desktop` vs. the packaged `termius-app.desktop`), use the existing one. Skip handlers with no desktop file and mention them to the user.

5. Add the entries to `xdg.mimeApps.defaultApplications` in `home/private.nix`, keeping the existing style. Strip stray whitespace in values. If a runtime value conflicts with an existing nix value, ask the user which one wins.

6. Rebuild the generated file (step 2) and confirm it contains every runtime entry.

7. Move the runtime copies out of the way (do not delete) so activation can proceed, e.g. into the session scratchpad. Tell the user where they went.

8. Run `nixfmt --check home/private.nix`. Tell the user to run `switch`; don't run it yourself (needs sudo).

Don't set `xdg.configFile."mimeapps.list".force = true` — it silently discards handlers apps register, which is the thing this skill exists to keep.
