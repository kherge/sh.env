Personalized Shell Environment Manager
======================================

Personalizes a shell environment with configurable options.

```sh
# Installs NVM.
option -e nvm

# Customizes PATH.
option -e path

# Install SDKMAN!.
option -e sdkman

# Installs Starship.rs.
option -e starship
```

Installation
------------

1. Clone this repository to `~/.local/share/sh.env`.
2. Add the following to `.bashrc` (or `.zshrc`, etc):
    ```sh
    ENV_DIR="$HOME/.local/share/sh.env"
    . "$ENV_DIR/env.sh"
    ```
3. Create a new or reload your shell session.

Usage
-----

Run `option -h` for usage information.

```
Usage: option [OPTION]
Manages shell personalization options.

OPTION

    -e  Enables an option.
    -d  Disables an option.
    -h  Displays this help message.
    -l  Lists available options.
```