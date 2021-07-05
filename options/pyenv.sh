#!/bin/sh
################################################################################
# pyenv Option                                                                 #
#                                                                              #
# This option will manage the installation and activation of pyenv. If pyenv   #
# is not installed, it will be cloned from the source.                         #
################################################################################

###
# Inititalizes pyenv.
##
__env_option_pyenv_activate()
{
    export PYENV_ROOT="$HOME/.pyenv"

    if ! eval "$(pyenv init -)"; then
        return 1
    fi
}

###
# Unregisters pyenv.
##
__env_option_pyenv_disable()
{
    # Clean up paths.
    if ! path remove '$HOME/.pyenv/bin'; then
        return 1
    fi

    if ! path remove '$HOME/.pyenv/shims'; then
        return 1
    fi

    # Clean up the runtime.
    unset PYENV_ROOT
    unset PYENV_SHELL

    unset _pyenv
    unset pyenv

    # Alert the user.
    echo "Please restart your session to unload pyenv."
}

###
# Installs and registers pyenv.
##
__env_option_pyenv_enable()
{
    if __env_option_disabled path; then
        __env_err "pyenv: path option is required"

        return 1
    fi

    if [ ! -d ~/.pyenv ]; then
        if ! command -v git > /dev/null; then
            __env_err "pyenv: git is required"

            return 1
        fi

        if ! git clone -q https://github.com/pyenv/pyenv.git ~/.pyenv; then
            __env_err "pyenv: could not clone pyenv"

            return 1
        fi
    fi

    if ! path add '$HOME/.pyenv/bin'; then
        return 1
    fi

    if ! path add '$HOME/.pyenv/shims'; then
        return 1
    fi
}