#!/bin/sh
################################################################################
# Personalized Shell Environment Manager                                       #
#                                                                              #
# This script is responsible for modifying the shell environment and for       #
# providing the user an interface with which to control what options are       #
# enabled. Some option scaffolding is also provided to provide a consistent    #
# option development experience.                                               #
################################################################################

# shellcheck disable=SC1090
# shellcheck disable=SC3043

################################################################################
# Internal                                                                     #
################################################################################

###
# Reads the value of a configuration setting from a file.
#
# @param  $1  The name of the setting.
#
# @stdout     The value of the setting.
#
# @return 0|1 If the value was read, `0`. Otherwise, `1`.
##
__env_config_get()
{
    local NAME="$1"

    if [ -f "$__ENV_CONFIG/$NAME" ]; then
        if ! cat "$__ENV_CONFIG/$NAME"; then
            __env_err "env: could not read configuration setting"

            return 1
        fi
    fi
}

###
# Sets the value of a configuration setting to a file.
#
# @param  $1  The name of the setting.
# @param  $2  The value of the setting.
#
# @return 0|1 If the value was set, `0`. Otherwise, `1`.
##
__env_config_set()
{
    local FILE="$__ENV_CONFIG/$1"
    local NAME="$1"
    local VALUE="$2"

    # Read value from STDIN.
    if [ "$VALUE" = '-' ]; then
        VALUE="$(cat -)"
    fi

    if [ "$VALUE" = '' ]; then
        if [ -f "$FILE" ] && ! rm "$FILE"; then
            __env_err "could not delete configuration setting"

            return 1
        fi
    elif ! echo "$VALUE" > "$FILE"; then
        __env_err "env: could not write configuration setting"

        return 1
    fi
}

###
# Prints to STDERR if DEBUG is `1`.
##
__env_debug()
{
    if [ "$DEBUG" = '1' ]; then
        echo "env [debug]:" "$@" >&2
    fi
}

###
# Prints to STDERR.
#
# @param $@ The message to print.
##
__env_err()
{
    echo env: "$@" >&2
}

###
# Adds an option to the enabled list.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_add()
{
    __env_debug "adding option..."

    local ENABLED
    local NAME="$1"

    if ! ENABLED="$(__env_config_get enabled)"; then
        return 1
    fi

    if [ "$__ENV_PRIORITY" = '' ]; then
        __env_debug "using default priority"

        __ENV_PRIORITY=50
    fi

    if [ "$ENABLED" = '' ]; then
        ENABLED="$__ENV_PRIORITY|$NAME"
    else
        ENABLED="$ENABLED
$__ENV_PRIORITY|$NAME"
        ENABLED="$(echo "$ENABLED" | sort)"
    fi

    __env_debug "added $NAME, priority $__ENV_PRIORITY"

    unset __ENV_PRIORITY

    if ! __env_config_set enabled "$ENABLED"; then
        return 1
    fi
}

###
# Invokes the disabler for an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_disable()
{
    __env_debug "disabling option..."

    local DISABLER="__env_option_${1}_disable"
    local FILE="$__ENV_DIR/options/$1.sh"
    local NAME="$1"

    if [ ! -f "$FILE" ]; then
        __env_err "$NAME: option does not exist"

        return 1
    fi

    if ! . "$FILE"; then
        __env_err "$NAME: option could not be loaded"

        return 1
    fi

    if type "$DISABLER" > /dev/null 2>&1; then
        __env_debug "disabler defined"

        if ! "$DISABLER"; then
            return 1
        fi
    else
        __env_debug "disabler not defined"
    fi

    unset "__env_option_${NAME}_activate"
    unset "__env_option_${NAME}_enable"
    unset "__env_option_${NAME}_disable"
}

###
# Checks if the option is disabled.
#
# @param  $1  The name of the option.
#
# @return 0|1 If disabled, `0`. Otherwise, `1`.
##
__env_option_disabled()
{
    if __env_option_enabled "$1"; then
        return 1
    fi

    return 0
}

###
# Invokes the enabler for an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_enable()
{
    __env_debug "enabling option..."

    local ACTIVATOR="__env_option_${1}_activate"
    local ENABLER="__env_option_${1}_enable"
    local FILE="$__ENV_DIR/options/$1.sh"
    local NAME="$1"

    if [ ! -f "$FILE" ]; then
        __env_err "$NAME: option does not exist"

        return 1
    fi

    if ! . "$FILE"; then
        __env_err "$NAME: option could not be loaded"

        return 1
    fi

    if type "$ENABLER" > /dev/null 2>&1; then
        __env_debug "enabler defined"

        if ! "$ENABLER"; then
            return 1
        fi
    else
        __env_debug "enabler not defined"
    fi

    if ! type "$ACTIVATOR" > /dev/null 2>&1; then
        __env_err "option does not have an activator"

        return 1
    fi

    if ! "$ACTIVATOR"; then
        __env_err "$NAME: option could not be activated"

        return 1
    fi

    unset "__env_option_${NAME}_activate"
    unset "__env_option_${NAME}_enable"
    unset "__env_option_${NAME}_disable"
}

###
# Checks if an option is enabled.
#
# @param  $1  The name of the option.
#
# @return 0|1 If enabled, `0`. Otherwise, `1`.
##
__env_option_enabled()
{
    __env_debug "checking if enabled..."

    local CONFIG="$__ENV_CONFIG/enabled"

    if [ -f "$CONFIG" ]; then
        if grep "|$1" "$CONFIG" > /dev/null; then
            __env_debug "option is enabled"

            return 0
        fi
    fi

    __env_debug "option is not enabled"

    return 1
}

###
# Removes an option from the enabled list.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_remove()
{
    __env_debug "removing option..."

    local ENABLED
    local NAME="$1"

    if ! ENABLED="$(__env_config_get enabled)"; then
        return 1
    fi

    ENABLED="$(echo "$ENABLED" | grep -v "|$NAME")"

    __env_debug "option removed"

    if ! __env_config_set enabled "$ENABLED"; then
        return 1
    fi
}

################################################################################
# Interface                                                                    #
################################################################################

###
# Disables an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
option_disable()
{
    __env_debug "option_disable()"

    if __env_option_enabled "$1"; then
        if __env_option_disable "$1"; then
            if __env_option_remove "$1"; then
                return 0
            fi
        fi

        return 1
    fi
}

###
# Enables an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
option_enable()
{
    __env_debug "option_enable()"

    if __env_option_disabled "$1"; then
        if __env_option_enable "$1"; then
            if __env_option_add "$1"; then
                return 0
            fi
        fi

        return 1
    fi
}

###
# Displays the help screen.
##
option_help()
{
    __env_debug "option_help()"

    cat - >&2 <<"HELP"
Usage: option [OPTION]
Manages shell personalization options.

OPTION

    -e  Enables an option.
    -d  Disables an option.
    -h  Displays this help message.
    -l  Lists available options.
HELP
}

###
# Lists all available options.
##
option_list()
{
    __env_debug "option_list()"

    local FILE
    local NAME

    echo "Available options:"
    echo

    find "$__ENV_DIR/options" -name '*.txt' | \
    sort | \
    while read -r FILE; do
        NAME="$(basename "$FILE" .txt)"

        if grep "|$NAME" "$__ENV_CONFIG/enabled" > /dev/null 2>&1; then
            echo "       (enabled)"
        else
            echo "      (disabled)"
        fi

        cat "$FILE"

        echo
    done
}

###
# Provides the user with a way of customizing their environment.
#
# @param  $@  The command arguments.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
option()
{
    __env_debug arguments: "$@"

    local OPTARG
    local OPTIND
    local OPTION

    while getopts d:e:hl OPTION; do
        __env_debug "option: $OPTION"

        case "$OPTION" in
            e) option_enable "$OPTARG";;
            d) option_disable "$OPTARG";;
            h) option_help;;
            l) option_list;;
            *) return 1;;
        esac
    done
}

################################################################################
# Initialize                                                                   #
################################################################################

###
# Loads an enabled option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successfully loaded, `0`. Otherwise, `1`.
##
__env_load()
{
    local ACTIVATOR="__env_option_$1_activate"
    local FILE="$__ENV_DIR/options/$1.sh"
    local NAME="$1"
    local STATUS=0

    if [ ! -f "$FILE" ]; then
        __env_err "$NAME: option does not exist"
    fi

    if ! . "$FILE"; then
        __env_err "$NAME: option could not be loaded"
    fi

    if ! type "$ACTIVATOR" > /dev/null 2>&1; then
        __env_err "$NAME: option does not have an activator"
    fi

    "$ACTIVATOR"

    STATUS=$?

    if [ $STATUS -ne 0 ]; then
        __env_err "$NAME [$STATUS]: option could not be activated"
    fi

    unset "__env_option_${NAME}_activate"
    unset "__env_option_${NAME}_enable"
    unset "__env_option_${NAME}_disable"
}

###
# Initializes the environment.
##
__env_init()
{
    # Configure the directory path to here.
    __ENV_DIR="$1"

    if [ "$__ENV_DIR" = '' ] && [ "$ENV_DIR" != '' ]; then
        __ENV_DIR="$ENV_DIR"
    fi

    if [ "$__ENV_DIR" = '' ]; then
        echo "env: no path set" >&2
        return 1
    fi

    # Discover the configuration settings path.
    if [ "$XDG_CONFIG_HOME" = '' ]; then
        export __ENV_CONFIG="$HOME/.config/env"
    else
        export __ENV_CONFIG="$XDG_CONFIG_HOME/env"
    fi

    # Make sure the directory exists.
    if [ ! -d "$__ENV_CONFIG" ]; then
        if ! mkdir -p "$__ENV_CONFIG"; then
            __env_err "could not create configuration directory"

	    return 1
        fi
    fi

    # Load enabled options.
    local ENABLED
    local OPTION

    if [ -f "$__ENV_CONFIG/enabled" ]; then
        while read -r ENABLED; do
            if [ "$ENABLED" != '' ]; then
                OPTION="$(echo "$ENABLED" | cut -d\| -f2)"

                if [ "$ALLOW" != '' ]; then
                    if echo "$ALLOW" | grep -F "+$OPTION" > /dev/null; then
                        __env_load "$OPTION"
                    else
                        __env_debug "$OPTION not allowed to be loaded"
                    fi
                else
                    __env_load "$OPTION"
                fi
            fi
        done < "$__ENV_CONFIG/enabled"
    fi

    unset __env_init
}

# Run the initializer.
__env_init "$1"

# Activate options in the wishlist.
if [ -f "$__ENV_CONFIG/wishlist" ]; then
    cat "$__ENV_CONFIG/wishlist" | while read -r OPTION; do
        option -e "$OPTION"
    done

    rm "$__ENV_CONFIG/wishlist"
fi
