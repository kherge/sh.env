#!/bin/sh
################################################################################
# NVM Support                                                                  #
#                                                                              #
# This option will manage the installation and activation of NVM. If NVM is    #
# not installed, it will be cloned from the source and the most recent version #
# is checked out.                                                              #
################################################################################

# shellcheck disable=SC1091
# shellcheck disable=SC3043

###
# Loads the NVM shell script.
##
__env_option_nvm_activate()
{
    # Set the directory path.
    if [ "$XDG_CONFIG_HOME" = '' ]; then
        export NVM_DIR="$HOME/.nvm"
    else
        export NVM_DIR="$XDG_CONFIG_HOME/nvm"
    fi

    # Load the shell script.
    . "$NVM_DIR/nvm.sh"

    return $?
}

###
# Cleans up.
##
__env_option_nvm_disable()
{
    # Clean up runtime.
    unset nvm

    unset NVM_BIN
    unset NVM_CD_FLAGS
    unset NVM_DIR
    unset NVM_INC
    unset NVM_RC_VERSION

    # Prompt the user.
    echo "Please restart your session to unload NVM."
}

###
# Installs NVM, if appropriate.
##
__env_option_nvm_enable()
{
    local NVM_DIR
    local REVISION
    local TAG
    local VERSION

    # Discover the directory path.
    if [ "$XDG_CONFIG_HOME" = '' ]; then
        NVM_DIR="$HOME/.nvm"
    else
        NVM_DIR="$XDG_CONFIG_HOME/nvm"
    fi

    # Download NVM if not installed.
    if [ ! -d "$NVM_DIR" ]; then
        if ! command -v git > /dev/null; then
            __env_err "nvm: git is required"

            return 1
        fi

        if ! git clone -q https://github.com/nvm-sh/nvm.git "$NVM_DIR"; then
            __env_err "nvm: could not clone NVM"

            return 1
        fi
    fi

    # Make sure a specific version is installed.
    if ! VERSION="$(__env_config_get nvm.version)"; then
        return 1
    fi

    if [ "$VERSION" = '' ]; then
        if ! REVISION="$(git --git-dir "$NVM_DIR/.git" rev-list --tags --max-count=1)"; then
            __env_err "nvm: could not get revision"

            return 1
        fi

        if ! TAG="$(git --git-dir "$NVM_DIR/.git" describe --abbrev=0 --tags --match "v[0-9]*" "$REVISION")"; then
            __env_err "nvm: could not get tag for revision"

            return 1
        fi

        if ! git --git-dir "$NVM_DIR/.git" --work-tree "$NVM_DIR" checkout -q "$TAG"; then
            __env_err "nvm: could not check out most recent version"

            return 1
        fi

        if ! __env_config_set nvm.version "$TAG"; then
            return 1
        fi
    fi
}
