#!/bin/sh
################################################################################
# Path Manager                                                                 #
#                                                                              #
# Manages the PATH environment variable to add, remove, and de-duplicate paths #
# in the variable. A new command is added to help make changes to the value.   #
################################################################################

# shellcheck disable=SC2016
# shellcheck disable=SC3043

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
        local COMMAND="$1"; shift

        case "$COMMAND" in
            ""|help)
                cat - >&2 <<'HERE'
Usage: path COMMAND PATH
Adds and removes managed paths.

The value of PATH is evaluated before it is added to $PATH in order to
support dynamic values. To support this evaluation, be sure to enclose
the value in single quotes (e.g. '$HOME/my/path').

ARGUMENTS

    COMMAND  The command to invoke.
    PATH     The path to be managed.

COMMAND

    add     Adds a managed path.
    has     Checks if a path is managed.
    help    Displays this help message.
    list    Displays all of the managed paths.
    remove  Removes a managed path.
    show    Shows PATH, each path on its own line (first to last used).

ADD

    When adding a path, an additional argument may be provided to specify
    the priority of the path among the other managed paths. The lower the
    number, the sooner the path is resolved before the others.

        path add '$HOME/.bin' 00
        path add '$HOME/.local/bin' 99

HAS

    If checking for managed paths in a programmatic manner, you may pass a
    -q option to silence the output. The return value can be used to check
    if the path is managed. A return value of 0 (zero) means it is managed,
    and 1 (one) means it is not.
HERE
                ;;

            add)
                __env_option_path_add "$@"
                return $?
                ;;

            has)
                __env_option_path_has "$@"
                return $?
                ;;

            list)
                __env_option_path_list "$@"
                return $?
                ;;

            remove)
                __env_option_path_remove "$@"
                return $?
                ;;

            show)
                __env_option_path_show "$@"
                return $?
                ;;

            *)
                __env_err "path: $COMMAND: invalid command"

                return 1
                ;;
        esac
    }
}

###
# Disables the path option.
##
__env_option_path_disable()
{
    # Clean up the runtime.
    unset __env_option_path_add
    unset __env_option_path_has
    unset __env_option_path_list
    unset __env_option_path_remove
    unset __env_option_path_replace
    unset __env_option_path_show
    unset path

    # Restore the original PATH.
    PATH="$__ENV_OPTION_PATH_ORIGINAL"
}

###
# Enables the path option.
##
__env_option_path_enable()
{
    # Make this option top priority, after the env option.
    export __ENV_PRIORITY=10

    # Set default paths.
    __env_option_path_add '$HOME/.local/bin' 99
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
    local NEW_PATH="$1"
    local PATHS
    local PRIORITY="$2"

    if [ "$NEW_PATH" = '' ]; then
        __env_err "env: path: path required"

        return 1
    fi

    PATHS="$(__env_config_get path.paths)"

    if echo "$PATHS" | grep "$NEW_PATH" > /dev/null; then
        return 0
    fi

    if [ "$PRIORITY" = '' ]; then
        PRIORITY=50
    fi

    if [ "$PATHS" = '' ]; then
        PATHS="$PRIORITY|$NEW_PATH"
    else
        PATHS="$PATHS
$PRIORITY|$1"
        PATHS="$(echo "$PATHS" | sort -r)"
    fi

    if ! __env_config_set path.paths "$PATHS"; then
        __env_err "env: path: could not update managed paths"

        return 1
    fi

    __env_option_path_replace
}

###
# Checks if a path is being managed.
#
# @param  $1  The path to check for.
# @param  $2  Set to `-q` to not print.
#
# @return 0|1 If managed, `0`. Otherwise, `1`.
##
__env_option_path_has()
{
    local CHECK="$1"
    local PATHS
    local QUIET="$2"

    if ! PATHS="$(__env_config_get path.paths)"; then
        return 1
    fi

    if echo "$PATHS" | grep "$CHECK" > /dev/null; then
        if [ "$QUIET" != '-q' ]; then
            echo "The path is managed."
        fi

        return 0
    fi

    if [ "$QUIET" != '-q' ]; then
        echo "The path is not managed."
    fi

    return 1
}

###
# Lists the paths that are managed.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_path_list()
{
    local MANAGED_PATH

    if [ -f "$__ENV_CONFIG/path.paths" ]; then
        while read -r MANAGED_PATH; do
            if [ "$MANAGED_PATH" != '' ]; then
                MANAGED_PATH="$(echo "$MANAGED_PATH" | cut -d\| -f2)"
                EVALED_PATH="$(eval "echo \"$MANAGED_PATH\"")"

                echo "$MANAGED_PATH -> $EVALED_PATH"
            fi
        done < "$__ENV_CONFIG/path.paths"
    fi
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
    local OLD_PATH="$1"
    local PATHS

    if [ "$OLD_PATH" = '' ]; then
        __env_err "env: path: path required"

        return 1
    fi

    PATHS="$(__env_config_get path.paths)"

    if ! echo "$PATHS" | grep "$OLD_PATH" > /dev/null; then
        return 0
    fi

    PATHS="$(echo "$PATHS" | grep -v "$OLD_PATH")"

    if ! __env_config_set path.paths "$PATHS"; then
        __env_err "env: path: could not update managed paths"

        return 1
    fi

    __env_option_path_replace
}

###
# Replaces the PATH value with the managed value.
##
__env_option_path_replace()
{
    local MANAGED_PATH

    PATH="$__ENV_OPTION_PATH_ORIGINAL"

    if [ -f "$__ENV_CONFIG/path.paths" ]; then
        while read -r MANAGED_PATH; do
            if [ "$MANAGED_PATH" != '' ]; then
                MANAGED_PATH="$(echo "$MANAGED_PATH" | cut -d\| -f2)"
                MANAGED_PATH="$(eval "echo \"$MANAGED_PATH\"")"

                if [ -d "$MANAGED_PATH" ] && \
                    ! echo "$PATH" | grep "$MANAGED_PATH:" > /dev/null; then
                    PATH="$MANAGED_PATH:$PATH"
                fi
            fi
        done < "$__ENV_CONFIG/path.paths"
    fi
}

###
# Shows the paths.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_path_show()
{
    echo "$PATH" | tr : "\n"
}
