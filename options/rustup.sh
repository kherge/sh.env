#!/bin/sh
################################################################################
# rustup Option                                                                #
#                                                                              #
# Adds support for rustup by downloading and installing it if it is not        #
# available. Once installed, the the Cargo path is added to PATH.              #
################################################################################

###
# Does nothing.
##
__env_option_rustup_activate()
{
    : # Do nothing.
}

###
# Cleans up.
##
__env_option_rustup_disable()
{
    if ! path remove '$HOME/.cargo/bin'; then
        return 1
    fi
}

###
# Installs rustup, if necessary.
##
__env_option_rustup_enable()
{
    if ! __env_config_get enabled | grep "|path" > /dev/null; then
        __env_err "rustup: the path option is required"

        return 1
    fi

    if ! command -v curl > /dev/null; then
        __env_err "rustup: curl is required"

        return 1
    fi

    if [ ! -d "$HOME/.cargo" ]; then
        if ! curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path; then
            return 1
        fi
    fi

    # install

    if ! path add '$HOME/.cargo/bin'; then
        return 1
    fi
}