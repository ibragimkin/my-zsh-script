# My Zsh Setup

Installs Oh My Zsh, the required plugins and tools, copies this repository's
`.zshrc` to your home directory, and sets Zsh as your default login shell.

## Install

Run as your normal user, without `sudo`:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ibragimkin/my-zsh-script/main/install.sh)"
```

`bash` and `curl` are needed to start the installer. They are included with
macOS. On Debian or Ubuntu, install `curl` first if necessary:

```bash
sudo apt-get update && sudo apt-get install -y curl
```

The installer uses Homebrew on macOS and `apt` on other systems to install
missing dependencies. An existing `~/.zshrc` is backed up before replacement.
You may be asked for your password when the default shell is changed.

Reconnect your terminal session after installation, or run:

```bash
exec zsh
```
