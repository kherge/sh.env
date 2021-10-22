#!/bin/sh
################################################################################
# Starship Prompt                                         https://starship.rs/ #
#                                                                              #
# Adds support for the Starship cross-shell prompt by installing it if it is   #
# not available. Once installed, the shell specific prompt is set.             #
################################################################################

###
# Initializes Starship for the supported shell.
##
__env_option_starship_activate()
{
    if command -v starship > /dev/null; then
        if [ "$BASH_VERSION" != '' ]; then
            eval "$(starship init bash)"
        elif [ "$ZSH_VERSION" != '' ]; then
            eval "$(starship init zsh)"
        else
            __env_debug "starship: shell not supported"

            return 1
        fi
    else
        __env_debug "starship: command not available"

        return 1
    fi
}

###
# Displays a message.
##
__env_option_starship_disable()
{
    # Prompt the user to reload.
    echo "Please restart your session to unload Starship."
}

###
# Sets the priority.
##
__env_option_starship_enable()
{
    # Should probably be the last thing loaded.
    export __ENV_PRIORITY=99

    # The cargo command is required.
    if ! command -v cargo > /dev/null; then
        __env_err "starship: cargo is required"

        return 1
    fi

    # Install Starship if not available.
    if ! command -v starship > /dev/null; then
        if ! cargo install starship; then
            return 1
        fi
    fi
}
