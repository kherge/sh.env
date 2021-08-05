#!/bin/sh
################################################################################
# Environment Variables Option                                                 #
#                                                                              #
# Provides the ability to cleanly manage exported environment variables,       #
# instead of directly editing the shell configuration script for each change.  #
################################################################################

################################################################################
# Option Handlers                                                              #
################################################################################

###
# Activates the option by defining a new command.
##
__env_option_var_activate()
{
    # Set environment variables.
    if ! __env_option_var_export_all; then
        return 1
    fi

    ###
    # Provides an interface for users to manage environment variables.
    #
    # @param  $1  The command.
    # @param  $@  The command arguments.
    #
    # @return 0|1 If successful, `0`. Otherwise, `1`.
    ##
    var()
    {
        local COMMAND="$1"; shift

        case "$COMMAND" in
            ""|help)
                cat - >&2 <<'HERE'
Usage: var COMMAND
Manages environment variables.

COMMANDS

    get   NAME        Displays the managed value of a variable.
    has   NAME        Checks if a variable is managed.
    help              Displays this help message.
    list              Lists all of the managed variables.
    reset NAME        Restores the managed value for a variable.
    set   NAME VALUE  Sets the managed value for a variable and exports it.
    unset NAME        Removes the managed value for a variable and unsets it.
HERE
                ;;

            get)
                __env_option_var_get "$@"
                return $?
                ;;

            has)
                __env_option_var_has "$@"
                return $?
                ;;

            list)
                __env_option_var_list "$@"
                return $?
                ;;

            reset)
                __env_option_var_reset "$@"
                return $?
                ;;

            set)
                __env_option_var_set "$@"
                return $?
                ;;

            unset)
                __env_option_var_unset "$@"
                return $?
                ;;

            *)
                __env_err "var: $COMMAND: invalid command"

                return 1
                ;;
        esac
    }
}

###
# Disables the var option.
##
__env_option_var_disable()
{
    # Clean up our runtime.
    unset __env_option_var_export
    unset __env_option_var_export_all
    unset __env_option_var_get
    unset __env_option_var_has
    unset __env_option_var_list
    unset __env_option_var_reset
    unset __env_option_var_set
    unset __env_option_var_unset
    unset var

    # Remove managed variables from the environment.
    # unset ...
}

###
# Enables the var option.
##
__env_option_var_enable()
{
    # Should probably be the first thing to load.
    __ENV_PRIORITY=00
}

################################################################################
# Option Internals                                                             #
################################################################################

###
# Evaluates a managed environment variabale value and exports it.
#
# @param $1 The managed environment variable.
##
__env_option_var_export()
{
    local VARIABLE="$1"
    local NAME="$(echo "$VARIABLE" | cut -d\| -f1)"
    local VALUE="$(echo "$VARIABLE" | cut -d\| -f2)"
          VALUE="$(eval "echo \"$VALUE\"")"

    export $NAME="$VALUE"
}

###
# Evaluates all of the managed variables and exports their values.
##
__env_option_var_export_all()
{
    if [ -f "$ENV_CONFIG/var.variables" ]; then
        local VARIABLE

        while read VARIABLE; do
            if [ "$VARIABLE" != '' ]; then
                __env_option_var_export "$VARIABLE"
            fi
        done < "$ENV_CONFIG/var.variables"
    fi
}

###
# Displays the managed value for a variable, evaluated and unevaluated.
##
__env_option_var_get()
{
    local MANAGED
    local NAME="$1"
    local VALUE
    local VARIABLE

    if [ "$NAME" = '' ]; then
        __env_err "env: var: variable name required"

        return 1
    fi

    if ! MANAGED="$(__env_config_get var.variables)"; then
        __env_err "env: var: could not get managed variables"

        return 1
    fi

    VARIABLE="$(echo "$MANAGED" | grep -F "$NAME|" | head -1)"
    VALUE="$(echo "$VARIABLE" | cut -d\| -f2)"

    echo "$VALUE -> $(eval "echo \"$VALUE\"")"

}

###
# Checks if a variable is managed.
##
__env_option_var_has()
{
    local MANAGED
    local NAME="$1"
    local QUIET="$2"
    local VARIABLE

    if [ "$NAME" = '' ]; then
        __env_err "env: var: variable name required"

        return 1
    fi

    if ! MANAGED="$(__env_config_get var.variables)"; then
        __env_err "env: var: could not get managed variables"

        return 1
    fi

    VARIABLE="$(echo "$MANAGED" | grep -F "$NAME|")"

    if [ "$VARIABLE" = '' ]; then
        if [ "$QUIET" != '-q' ]; then
            echo "The variable is not managed."
        fi

        return 1
    elif [ "$QUIET" != '-q' ]; then
        echo "The variable is managed."
    fi

    return 0
}

###
# Lists all of the managed variables and their values.
##
__env_option_var_list()
{
    local LENGTh
    local NAME
    local VALUE
    local VARIABLE

    if [ -f "$ENV_CONFIG/var.variables" ]; then
        while read VARIABLE; do
            if [ "$VARIABLE" != '' ]; then
                NAME="$(echo "$VARIABLE" | cut -d\| -f1)"
                VALUE="$(echo "$VARIABLE" | cut -d\| -f2)"

                echo "$NAME = $VALUE -> $(eval "echo \"$VALUE\"")"
            fi
        done < "$ENV_CONFIG/var.variables"
    fi
}

###
# Re-exports the original managed value for a variable.
##
__env_option_var_reset()
{
    local MANAGED
    local NAME="$1"
    local VARIABLE

    if [ "$NAME" = '' ]; then
        __env_err "env: var: variable name required"

        return 1
    fi

    if ! MANAGED="$(__env_config_get var.variables)"; then
        __env_err "env: var: could not get managed variables"

        return 1
    fi

    VARIABLE="$(echo "$MANAGED" | grep -F "$NAME|" | head -1)"

    __env_option_var_export "$VARIABLE"
}

###
# Sets the managed value for a variable and immediately exports it.
##
__env_option_var_set()
{
    local MANAGED
    local NAME="$1"
    local VALUE="$2"

    if [ "$NAME" = '' ]; then
        __env_err "env: var: variable name required"

        return 1
    fi

    if ! MANAGED="$(__env_config_get var.variables)"; then
        __env_err "env: var: could not get managed variables"

        return 1
    fi

    VARIABLE="$NAME|$VALUE"
    MANAGED="$(echo "$MANAGED" | grep -vF "$NAME|")"
    MANAGED="$MANAGED
$VARIABLE"
    MANAGED="$(echo "$MANAGED" | sort)"

    if ! __env_config_set var.variables "$MANAGED"; then
        return 1
    fi

    __env_option_var_export "$VARIABLE"
}

###
# Removes the managed value for a variable and immediately unsets it.
##
__env_option_var_unset()
{
    local MANAGED
    local NAME="$1"

    if [ "$NAME" = '' ]; then
        __env_err "env: var: variable name required"

        return 1
    fi

    if ! MANAGED="$(__env_config_get var.variables)"; then
        __env_err "env: var: could not get managed variables"

        return 1
    fi

    MANAGED="$(echo "$MANAGED" | grep -vF "$NAME|")"

    if ! __env_config_set var.variables "$MANAGED"; then
        return 1
    fi

    unset "$NAME"
}
