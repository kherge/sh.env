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
        local COMMAND="$1"; shift

        case "$COMMAND" in
            ""|-h)
                __env_err <<'HERE'
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
    remove  Removes a managed path.

ADD

    When adding a path, an additional argument may be provided to specify
    the priority of the path among the other managed paths. The lower the
    number, the sooner the path is resolved before the others.

        path add '$HOME/.bin' 00
        path add '$HOME/.local/bin' 99
HERE
                ;;

            add)
                __env_option_path_add "$@"
                return $?
                ;;

            remove)
                __env_option_path_remove "$@"
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
    unset __env_option_path_remove
    unset __env_option_path_replace
    unset path

    # Restore the original PATH.
    PATH="$__ENV_OPTION_PATH_ORIGINAL"
}

###
# Enables the path option.
##
__env_option_path_enable()
{
    # Make this option top priority.
    __ENV_PRIORITY=00

    # Set default paths.
    __env_option_path_add '$HOME/.cargo/bin'
    __env_option_path_add '$HOME/.local/bin' 99
    __env_option_path_add '$HOME/.phpenv/bin'
    __env_option_path_add '$HOME/.rvm/bin'
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

    if [ -f "$ENV_CONFIG/path.paths" ]; then
        while read -r MANAGED_PATH; do
            if [ "$MANAGED_PATH" != '' ]; then
                MANAGED_PATH="$(echo "$MANAGED_PATH" | cut -d\| -f2)"
                MANAGED_PATH="$(eval "echo \"$MANAGED_PATH\"")"

                if [ -d "$MANAGED_PATH" ] && \
                    ! echo "$PATH" | grep "$MANAGED_PATH:" > /dev/null; then
                    PATH="$MANAGED_PATH:$PATH"
                fi
            fi
        done < "$ENV_CONFIG/path.paths"
    fi
}
