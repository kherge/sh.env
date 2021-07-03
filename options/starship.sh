#!/bin/sh
################################################################################
# Starship Prompt                                         https://starship.rs/ #
#                                                                              #
# Activates Starship if it is available in PATH.                               #
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
            echo "env: starship: shell not supported" >&2
            echo >&2
        fi
    else
        echo "env: starship: command not available" >&2
        echo >&2
    fi
}

###
# Does nothing.
##
__env_option_starship_disable()
{
    # Prompt the user to reload.
    echo "Please restart your session to unload Starship."
}

###
# Does nothing.
##
__env_option_starship_enable()
{
    # Should probably be the last thing loaded.
    __ENV_PRIORITY=99
}
