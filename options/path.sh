#!/bin/sh
################################################################################
# Path Manager                                                                 #
#                                                                              #
# Manages the PATH environment variable to add, remove, and de-duplicate paths #
# in the variable. A new command is added to help make changes to the value.   #
################################################################################

# Remember the original PATH.
__ENV_OPTION_PATH_ORIGINAL="$PATH"

################################################################################
# Option Handlers                                                              #
################################################################################

###
# Enables the option by defining a new command.
##
__env_option_path_activate()
{
    # Replace PATH.
    if ! __env_option_path_replace; then
        return 1
    fi

    ###
    # Provides an interface for users to manage paths with.
    #
    # @param  $1  The command.
    # @param  $@  The command arguments.
    #
    # @return 0|1 If successful, `0`. Otherwise, `1`.
    ##
    path()
    {
        case "$1" in
            add)
                shift
                __env_option_path_add "$@"
                return $?
                ;;

            remove)
                shift
                __env_option_path_remove "$@"
                return $?
                ;;

            *)
                echo "Usage: path COMMAND" >&2
                echo >&2
                echo "COMMAND" >&2
                echo >&2
                echo "    add     Adds a managed path." >&2
                echo "    remove  Removes a managed path." >&2
                echo >&2

                return 3
                ;;
        esac
    }
}

###
# Disables the path option.
##
__env_option_path_disable()
{
    while getopts dh OPTION; do
        case "$OPTION" in
            d) __env_config_set path.paths "";;
            h|*)
                echo "Usage: option disable path [OPTION]" >&2
                echo >&2
                echo "OPTION" >&2
                echo >&2
                echo "    -d  Deletes settings." >&2
                echo "    -h  Displays this help message." >&2
                echo >&2

                return 1
                ;;
        esac
    done
}

###
# Enables the path option.
##
__env_option_path_enable()
{
    # Make this option top priority.
    __ENV_PRIORITY=00

    # Set flags.
    __ENV_DEFAULTS=1

    while getopts hnr OPTION; do
        case "$OPTION" in
            n) __ENV_DEFAULTS=0;;
            r)
                __env_config_set path.paths ""
                ;;
            h|*)
                echo "Usage: option enable path [OPTION]" >&2
                echo >&2
                echo "OPTION" >&2
                echo >&2
                echo "    -n  Do not initialize with default paths." >&2
                echo "    -r  Deletes settings before initializing." >&2
                echo >&2

                unset __ENV_DEFAULTS

                return 1
                ;;
        esac
    done

    # Set default paths.
    if [ $__ENV_DEFAULTS -eq 1 ]; then
        __env_option_path_add '$HOME/.cargo/bin'
        __env_option_path_add '$HOME/.local/bin' 99
        __env_option_path_add '$HOME/.phpenv/bin'
        __env_option_path_add '$HOME/.rvm/bin'
    fi

    unset __ENV_DEFAULTS
}

################################################################################
# Option Internals                                                             #
################################################################################

###
# Adds a managed path.
#
# @param  $1  The path to add.
# @param  $2  The priority of the path.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_path_add()
{
    if [ "$1" = '' ]; then
        echo "env: path: path required" >&2

        return 1
    fi

    __ENV_PATHS="$(__env_config_get path.paths)"

    if echo "$__ENV_PATHS" | grep "$1" > /dev/null; then
        unset __ENV_PATHS

        return 0
    fi

    __ENV_PATH_PRIORITY=50

    if [ "$2" != '' ]; then
        __ENV_PATH_PRIORITY=$2
    fi

    __ENV_PATHS="$__ENV_PATHS
$__ENV_PATH_PRIORITY|$1"
    __ENV_PATHS="$(echo "$__ENV_PATHS" | sort -r)"

    if ! __env_config_set path.paths "$__ENV_PATHS"; then
        unset __ENV_PATHS
        unset __ENV_PATH_PRIORITY

        echo "env: path: could not update managed paths" >&2

        return 1
    fi

    __env_option_path_replace

    unset __ENV_PATH_PRIORITY
    unset __ENV_PATHS
}

###
# Removes a managed path.
#
# @param  $1  The path to remove.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_path_remove()
{
    if [ "$1" = '' ]; then
        echo "env: path: path required" >&2

        return 1
    fi

    __ENV_PATHS="$(__env_config_get path.paths)"

    if ! echo "$__ENV_PATHS" | grep "$1" > /dev/null; then
        unset __ENV_PATHS

        return 0
    fi

    __ENV_PATHS="$(echo "$__ENV_PATHS" | grep -v "$1")"

    if ! __env_config_set path.paths "$__ENV_PATHS"; then
        echo "env: path: could not update managed paths" >&2

        unset __ENV_PATHS

        return 1
    fi

    __env_option_path_replace

    unset __ENV_PATHS
}

###
# Replaces the PATH value with the managed value.
##
__env_option_path_replace()
{
    PATH="$__ENV_OPTION_PATH_ORIGINAL"

    if [ -f "$ENV_CONFIG/path.paths" ]; then
        while read -r __ENV_MANAGED_PATH; do
            if [ "$__ENV_MANAGED_PATH" != '' ]; then
                __ENV_MANAGED_PATH="$(echo "$__ENV_MANAGED_PATH" | cut -d\| -f2)"
                __ENV_MANAGED_PATH="$(eval "echo \"$__ENV_MANAGED_PATH\"")"

                if [ -d "$__ENV_MANAGED_PATH" ] && \
                    ! echo "$PATH" | grep "$__ENV_MANAGED_PATH:" > /dev/null; then
                    PATH="$__ENV_MANAGED_PATH:$PATH"
                fi
            fi
        done < "$ENV_CONFIG/path.paths"
    fi

    unset __ENV_MANAGED_PATH
    unset __ENV_PATHS
}
