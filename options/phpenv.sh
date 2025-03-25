#!/bin/sh
################################################################################
# phpenv Option                                                                #
#                                                                              #
# This option will manage the installation and activation of phpenv. If phpenv #
# is not installed, it will be cloned from the source.                         #
################################################################################

# shellcheck disable=SC2016

###
# Inititalizes phpenv.
##
__env_option_phpenv_activate()
{
    eval "$(phpenv init -)"
}

###
# Unregisters phpenv.
##
__env_option_phpenv_disable()
{
    if ! path remove '$HOME/.phpenv/bin'; then
        return 1
    fi

    if [ -d "$HOME/.phpenv" ]; then
        if ! rm -Rf "$HOME/.phpenv"; then
            __env_err "phpenv: unable to clean up repo"
        fi
    fi
}

###
# Installs and registers phpenv.
##
__env_option_phpenv_enable()
{
    if ! command -v git > /dev/null; then
        __env_err "phpenv: git is required"

        return 1
    fi

    if __env_option_disabled path; then
        __env_err "phpenv: path option is required"

        return 1
    fi

    if [ ! -d "$HOME/.phpenv" ]; then
        if ! git clone https://github.com/phpenv/phpenv.git "$HOME/.phpenv"; then
            __env_err "phpenv: unable to install from repo"

            return 1
        fi
    fi

    if ! path add '$HOME/.phpenv/bin'; then
        return 1
    fi
}
