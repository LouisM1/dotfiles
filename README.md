# Louis's dotfiles

Portable snapshot of the terminal setup on 9 November 2026: Zsh, Oh My Zsh,
Powerlevel10k, autosuggestions, fzf, tmux, Ghostty and Git.

## Set up a new Mac

Install Apple's command-line tools (`xcode-select --install`) and Homebrew from
https://brew.sh. Clone this private repository to a permanent location such as
`~/dotfiles`, then run from that directory:

```sh
./install.sh --dry-run --packages
./install.sh --packages
```

The installer installs the core Homebrew tools and Ghostty, clones the recorded
versions of shell/plugin dependencies, and links the configuration files into
your home directory. Existing files are moved to
`~/.dotfiles-backups/<timestamp>-<process>/` before replacement. Existing plugin
and runtime directories are kept, with a message if their version differs.
The install is repeatable. Keep the repository in place because the settings
are symlinks to it. Open a new Ghostty window after installation.

On a fresh Mac, macOS's default Zsh is sufficient. Installing the Homebrew Zsh
package does not change your account's login shell.

For the wider set of previously installed Homebrew packages, apps, VS Code
extensions and detected npm tools instead:

```sh
./install.sh --full-packages
```

Review `Brewfile.full` first: it includes MacTeX, Warp and other non-terminal apps.
Homebrew installs available versions, not necessarily the versions recorded in
`manifests/homebrew-versions.txt`. Some old packages may no longer be available.
The full export used `brew bundle dump --no-uv`; the uv tools directory was empty.

If you have already installed the dependencies, `./install.sh --skip-deps` only
links the configuration. `--target /absolute/path` is available for inspecting
or testing the file layout. Package installation always affects the current
machine; do not combine a test target with package installation.

## What is preserved

- `zsh/`: shell settings, prompt, aliases, NVM startup, autosuggestions and fzf.
- `tmux/tmux.conf`: the actual active configuration: mouse support and a minimal
  top window bar, with TPM.
- `ghostty/config`: Shift+Enter, Command+B and Command+R bindings, translucency
  and blur. Installed to the original macOS Application Support location.
- `git/`: Git identity and global ignore rules.
- `dependencies.tsv`: public upstream URLs and exact installed commits for
  Oh My Zsh, Powerlevel10k, zsh-autosuggestions, TPM, minimal-tmux-status and NVM.
  Dependencies are downloaded on installation; their old Git history/config,
  caches and binaries are not copied into this repository. Initial checkouts are
  detached at the recorded commits. Use the tools' own update procedures later.
- `archive/`: older Oh My Tmux local configurations for reference. The active
  config no longer loads them. minimal-tmux-status is restored as an installed
  plugin but remains inactive, matching the source laptop.
- `manifests/`: installed versions, runtime information, fonts and local commands.

The source laptop's hardcoded username path was changed to `$HOME`. Homebrew
startup supports both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`).
Ruby startup is guarded until rbenv is installed. Put private or machine-specific
shell settings in `~/.zshrc.local`, which is loaded last and is not tracked.

## Language runtimes and additional commands

NVM itself is restored, but Node installations and global packages are not copied.
The source laptop has Node **20.18.3**, NVM default alias **20**, and Ruby **3.0.0**.
Those versions are recorded for compatibility; use project requirements to decide
whether to restore those old versions or use newer supported releases.

To reproduce the recorded Node version in a new terminal:

```sh
nvm install 20.18.3
nvm alias default 20
nvm use default
```

Review `manifests/runtimes.json` for the observed global npm package versions.
It records the Homebrew npm invocation; the Brewfile also includes the tools
Homebrew detected in its own environment. Install the packages you need under
the Node version you intend to use. Neither inventory is a project dependency lockfile.

For the old Ruby version, if needed:

```sh
rbenv install 3.0.0
rbenv global 3.0.0
```

That old Ruby may need additional work on a newer macOS. Project dependencies,
Ruby gems and Python virtual environments should be recreated from project files.
The recorded pipx application is NumPy 2.1.2 (`pipx install numpy==2.1.2`).

The source `~/.local/bin` contains only application-managed symlinks: Poetry,
Cursor Agent, f2py and numpy-config. Reinstall their owning tools rather than
copying broken absolute symlinks. Bun was also present; reinstall it from its
official installer if used. Windsurf's shell path is preserved, but the app must
be installed separately. See `manifests/local-commands.json`.

## Fonts, credentials and state

Ghostty's active config does not select a custom font. User-installed font names
are recorded in `manifests/fonts.txt`; font binaries (including trial/commercial
fonts) are not published. Transfer any desired fonts privately according to their
licenses. Ghostty's bundled font covers the current terminal configuration.

SSH keys/config, cloud credentials, API tokens, shell history, caches, compiled
binaries and running tmux sessions are not included. Sign in to your tools on the
new Mac. A credential-bearing plugin remote URL on the source machine was replaced
with its clean public upstream URL in the dependency manifest.

The installer preserves your existing `~/.zshrc.local`. Ghostty's alternate
`config.ghostty` in the same macOS directory is backed up so it cannot override the
restored file. An existing XDG Ghostty configuration is retained and can supply
additional settings; inspect it if your appearance differs.

## Update your settings

Edit the files in this repository (or through their home-directory symlinks), then:

```sh
git diff
git add zsh tmux ghostty git
git commit -m "Update terminal settings"
git push
```

Review changes for credentials before committing. On another laptop, `git pull`
updates linked settings; open a new terminal and reload/restart tmux as appropriate.
Rerun the installer for newly added links or dependencies. The original laptop's
live settings have not been switched to these symlinks by the extraction process.

## Restore previous settings

Each replaced file is kept under the corresponding relative path inside the
backup directory printed by the installer. Remove the relevant symlink, then
move its saved original back to that location. Existing dependency directories
are never reset or deleted by the installer.
