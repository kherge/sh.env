#!/bin/sh
################################################################################
# RVM Option                                                                   #
#                                                                              #
# This script provides an example of how an option script should be created    #
# for the environment personalizer. The script also attempts to define a set   #
# of best practices in code.                                                   #
################################################################################

# shellcheck disable=SC1091
# shellcheck disable=SC3043

###
# Loads the RVM shell script.
##
__env_option_rvm_activate()
{
    local RVM_DIR="$HOME/.rvm"

    # Require BASH or ZSH.
    if [ "$BASH_VERSION" = '' ] && [ "$ZSH_VERSION" = '' ]; then
        __env_debug "rvm: BASH or ZSH is required"

        return 1
    fi

    # Load the shell script.
    . "$RVM_DIR/scripts/rvm"
}

###
# Cleans up.
##
__env_option_rvm_disable()
{
    # Do minimal clean up.
    #
    # If you have RVM enabled in BASH, run `declare -F | grep -i rvm` and `declare -p | grep -i rvm`
    # to see everything that the RVM shell script defines. It pollutes the defined functions and
    # variables to the point that it is simply easier to just unset the `rvm` function and call it
    # a day. Not as clean as I would like.
    unset rvm

    # Prompt the user.
    echo "Please restart your session to unload RVM."
}

###
# Installs RVM, if appropriate.
##
__env_option_rvm_enable()
{
    local RVM_DIR="$HOME/.rvm"

    # Download RVM if not installed.
    if [ ! -d "$RVM_DIR" ]; then
        if ! command -v bash > /dev/null; then
            __env_err "rvm: bash is required to install"

            return 1
        fi

        if ! command -v curl > /dev/null; then
            __env_err "rvm: curl is required to install"

            return 1
        fi

        if ! curl -sSL https://get.rvm.io | bash -s -- --ignore-dotfiles; then
            __env_err "rvm: install script failed"

            return 1
        fi
    fi
}
