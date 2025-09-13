#!/bin/sh

# shellcheck disable=SC1090
# shellcheck disable=SC3043

# @description Wraps the initialization function to support graceful exits.
#
# @see __env_init_inner()
__env_init()
{
    # Initialize with graceful exit.
    __env_init_inner "$@"

    # Capture the exit status.
    local STATUS=$?

    # Self destruct
    unset -f __env_init

    # Restore original exit status.
    return $STATUS
}

# @description Initializes the integration of environment customizations.
#
# @arg $1 The directory path to this shell script.
#
# @exitcode 0 If initialized.
# @exitcode 1 If not initialized.
__env_init_inner()
{
    export __ENV_DIR="$1"

    # Make sure the path is correct.
    if [ ! -d "$__ENV_DIR" ]; then
        unset __ENV_DIR

        __env_error "no such directory: $__ENV_DIR"

        return 1
    elif [ ! -f "$__ENV_DIR/env.sh" ]; then
        __env_error "invalid directory path"

        return 1
    fi

    # Load the core functions.
    . "$__ENV_DIR/core.sh"

    # Announce state.
    __env_debug initialized

    # Self destruct
    unset -f __env_init_inner
}