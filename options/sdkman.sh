#!/bin/sh
################################################################################
# SDKMAN! Option                                                               #
#                                                                              #
# This option will manage the installation and activation of SDKMAN!. If       #
# SDKMAN! is not installed, the installation script will be downloaded and     #
# executed.                                                                    #
################################################################################

###
# Initializes SDKMAN!.
##
__env_option_sdkman_activate()
{
    # Make sure we are in BASH or ZSH.
    if [ "$BASH_VERSION" = '' ] && [ "$ZSH_VERSION" = '' ]; then
        __env_debug "sdkman: BASH or ZSH is required"

        return 1
    fi

    # Load the shell script.
    . "$HOME/.sdkman/bin/sdkman-init.sh"

    return $?
}

###
# Cleans up.
##
__env_option_sdkman_disable()
{
    # Clean up the runtime.
    unset sdk

    unset SDKMAN_CANDIDATES_API
    unset SDKMAN_CANDIDATES_DIR
    unset SDKMAN_PLATFORM
}

###
# Install SDKMAN!, if necessary.
##
__env_option_sdkman_enable()
{
    # Install if not available.
    if [ ! -d "$HOME/.sdkman" ]; then
        if ! command -v curl > /dev/null; then
            __env_err "sdkman: curl is required"

            return 1
        fi

        local SHELL=

        if command -v bash > /dev/null; then
            SHELL=bash
        elif command -v zsh > /dev/null; then
            SHELL=zsh
        else
            __env_err "sdkman: BASH or ZSH is required"

            return 1
        fi

        if ! curl -s "https://get.sdkman.io?rcupdate=false" | "$SHELL"; then
            __env_err "sdkman: could not be installed"

            return 1
        fi
    fi
}
