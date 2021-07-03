#!/bin/sh
################################################################################
# Personalized Shell Environment Manager                                       #
#                                                                              #
# This script is responsible for modifying the shell environment and for       #
# providing the user an interface with which to control what options are       #
# enabled. Some option scaffolding is also provided to provide a consistent    #
# option development experience.                                               #
################################################################################

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

    if [ -f "$ENV_CONFIG/$NAME" ]; then
        if ! cat "$ENV_CONFIG/$NAME"; then
            echo "env: could not read configuration setting" >&2

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
    local NAME="$1"
    local VALUE="$2"

    # Read value from STDIN.
    if [ "$VALUE" = '-' ]; then
        VALUE="$(cat -)"
    fi

    if ! echo "$VALUE" > "$ENV_CONFIG/$NAME"; then
        echo "env: could not write configuration setting" >&2

        return 1
    fi
}

###
# Prints to STDERR if DEBUG is `1`.
##
__env_debug()
{
    if [ "$DEBUG" = '1' ]; then
        echo "env; $*" >&2
    fi
}

###
# Prints to STDERR.
#
# @param $@ The message to print.
##
__env_err()
{
    echo "env: $*" >&2
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
    local ENABLED
    local NAME="$1"

    if ! ENABLED="$(__env_config_get enabled)"; then
        return 1
    fi

    if [ "$__ENV_PRIORITY" = '' ]; then
        __ENV_PRIORITY=50
    fi

    if [ "$ENABLED" = '' ]; then
        ENABLED="$__ENV_PRIORITY|$NAME"
    else
        ENABLED="$ENABLED
$__ENV_PRIORITY|$NAME"
        ENABLED="$(echo "$ENABLED" | sort)"
    fi

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
    local DISABLER="__env_option_${1}_disable"
    local FILE="$ENV_DIR/options/$1.sh"
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
        if ! "$DISABLER"; then
            return 1
        fi
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
    local ENABLER="__env_option_${1}_enable"
    local FILE="$ENV_DIR/options/$1.sh"
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
        if ! "$ENABLER"; then
            return 1
        fi
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
    local CONFIG="$ENV_CONFIG/enabled"

    if [ -f "$CONFIG" ]; then
        if grep "|$1" "$CONFIG" > /dev/null; then
            return 0
        fi
    fi

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
    local ENABLED
    local NAME="$1"

    if ! ENABLED="$(__env_config_get enabled)"; then
        return 1
    fi

    ENABLED="$(echo "$ENABLED" | grep -v "|$NAME")"

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
    if __env_option_enabled "$1"; then
        if __env_option_disable "$1"; then
            __env_option_remove "$1"
        fi
    fi

    return $?
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
    if __env_option_disabled "$1"; then
        if __env_option_enable "$1"; then
            __env_option_add "$1"
        fi
    fi

    return $?
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
    local OPTION

    while getopts d:e: OPTION; do
        case "$OPTION" in
            e) option_enable "$OPTARG";;
            d) option_disable "$OPTARG";;
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
    local FILE="$ENV_DIR/options/$1.sh"
    local NAME="$1"

    if [ ! -f "$FILE" ]; then
        __env_err "$NAME: option does not exist"
    fi

    if ! . "$FILE"; then
        __env_err "$NAME: option could not be loaded"
    fi

    if ! type "$ACTIVATOR" > /dev/null 2>&1; then
        __env_err "$NAME: option does not have an activator"
    fi

    if ! "$ACTIVATOR"; then
        __env_err "$NAME: option could not be activated"
    fi
}

###
# Initializes the environment.
##
__env_init()
{
    # Discover the configuration settings path.
    if [ "$XDG_CONFIG_HOME" = '' ]; then
        export ENV_CONFIG="$HOME/.config/env"
    else
        export ENV_CONFIG="$XDG_CONFIG_HOME/env"
    fi

    # Load enabled options.
    local ENABLED
    local OPTION

    if [ -f "$ENV_CONFIG/enabled" ]; then
        while read -r ENABLED; do
            OPTION="$(echo "$ENABLED" | cut -d\| -f2)"

            __env_load "$OPTION"
        done < "$ENV_CONFIG/enabled"
    fi

    unset __env_init
    unset __env_load
}

# Run the initializer.
__env_init
