#!/bin/sh
################################################################################
# Personalized Shell Environment Manager                                       #
#                                                                              #
# This script is responsible for modifying the shell environment and for       #
# providing the user an interface with which to control what options are       #
# enabled. Some scaffolding is also provided to the separate options to        #
# provide a consistent option development experience.                          #
################################################################################

################################################################################
# Internal                                                                     #
################################################################################

###
# Activates an enabled option.
#
# @param  $1  The name of the option.
#
# @return 0|1 Returns `0` if successful, or `1` if not.
##
__env_activate()
{
    if [ ! -f "$ENV_DIR/options/$1.sh" ]; then
        echo "env: $1: no such option" >&2

        return 1
    fi

    if type "__env_option_$1_activate" > /dev/null 2>&1; then
        echo "env: $1: already loaded" >&2

        return 0
    fi

    if ! . "$ENV_DIR/options/$1.sh"; then
        echo "env: $1: could not be loaded" >&2

        return 1
    fi

    if ! type "__env_option_$1_activate" > /dev/null 2>&1; then
        echo "env: $1: does not have an activation function" >&2

        return 1
    fi

    if ! "__env_option_$1_activate"; then
        echo "env: $1: could not be activated"

        return 1
    fi

    __env_clean "$1"
}

###
# Bootstraps the personalized environment.
##
__env_bootstrap()
{
    # Defines requires environment variables.
    if [ "$XDG_CONFIG_HOME" = '' ]; then
        export ENV_CONFIG="$HOME/.config/env"
    else
        export ENV_CONFIG="$XDG_CONFIG_HOME/env"
    fi

    # Ensure the configuration directories exist.
    if [ ! -d "$ENV_CONFIG" ]; then
        if ! mkdir -p "$ENV_CONFIG"; then
            echo "env: could not create config directory" >&2
            echo "     this directory is required for the" >&2
            echo "     personalization to function properly" >&2

            return 1
        fi
    fi

    # Activate the enabled options.
    if [ -f "$ENV_CONFIG/enabled" ]; then
        while read -r __ENV_OPTION; do
            if [ "$__ENV_OPTION" != '' ]; then
                __ENV_OPTION="$(echo "$__ENV_OPTION" | cut -d\| -f2)"

                __env_activate "$__ENV_OPTION"
            fi
        done < "$ENV_CONFIG/enabled"

        unset __ENV_OPTION
    fi
}

###
# Cleans up option handler functions when no longer needed.
#
# @param $1 The name of the option.
##
__env_clean()
{
    unset "__env_option_$1_activate"
    unset "__env_option_$1_disable"
    unset "__env_option_$1_enable"
}

###
# Retrieves the value of a configuration setting.
#
# @param  $1  The name of the setting.
#
# @stdout     The value of the setting.
#
# @return 0|1 If the setting exists, `0`. If not or error reading, `1`.
##
__env_config_get()
{
    if [ "$1" = '' ]; then
        echo "env: setting name required" >&2

        return 1
    fi

    if [ -f "$ENV_CONFIG/$1" ]; then
        cat "$ENV_CONFIG/$1"

        return $?
    fi

    return 1
}

###
# Sets the value of a configuration setting.
#
# @param  $1  The name of the setting.
# @param  $2  The value of the setting.
#
# @return 0|1 If set, `0`. If error writing, `1`.
##
__env_config_set()
{
    if [ "$1" = '' ]; then
        echo "env: setting name required" >&2

        return 1
    fi

    # Using STDIN, replace value.
    if [ "$2" = '-' ]; then
        set -- "$1" "$(cat -)"
    fi

    # If there is no value, delete if it exists.
    if [ "$2" = '' ]; then
        if [ -f "$ENV_CONFIG/$1" ]; then
            if ! rm "$ENV_CONFIG/$1"; then
                return 1
            fi
        fi

    # Set the value.
    elif ! echo "$2" > "$ENV_CONFIG/$1"; then
        return 1
    fi
}

###
# Disables an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successfully disabled, `0`. Otherwise, `1`.
##
__env_disable()
{
    if [ "$1" = '' ]; then
        echo "env: option name required" >&2

        return 1
    fi

    __ENV_OPTION="$1"; shift

    if ! grep "|$__ENV_OPTION" "$ENV_CONFIG/enabled" > /dev/null 2>&1; then
        echo "env: $__ENV_OPTION: not enabled" >&2

        unset __ENV_OPTION

        return 0
    fi

    if ! type "__env_option_${__ENV_OPTION}_disable" > /dev/null 2>&1; then
        if [ ! -f "$ENV_DIR/options/$__ENV_OPTION.sh" ]; then
            echo "env: $__ENV_OPTION: no such option" >&2

            unset __ENV_OPTION

            return 1
        fi

        if ! . "$ENV_DIR/options/$__ENV_OPTION.sh"; then
            echo "env: $__ENV_OPTION: could not be loaded" >&2

            unset __ENV_OPTION

            return 1
        fi

        if ! type "__env_option_${__ENV_OPTION}_disable" > /dev/null 2>&1; then
            echo "env: $__ENV_OPTION: does not have a disabler function" >&2

            unset __ENV_OPTION
            __env_clean "$__ENV_OPTION"

            return 1
        fi
    fi

    if ! "__env_option_${__ENV_OPTION}_disable" "$@"; then
        echo "env: $__ENV_OPTION: could not be disabled" >&2

        unset __ENV_OPTION
        __env_clean "$__ENV_OPTION"

        return 1
    fi

    if [ "$__ENV_PRIORITY" = '' ]; then
        __ENV_PRIORITY=50
    fi

    if [ -f "$ENV_CONFIG/enabled" ]; then
        if ! __ENV_ENABLED="$(cat "$ENV_CONFIG/enabled")"; then
            unset __ENV_OPTION
            __env_clean "$__ENV_OPTION"

            echo "env: could not read enabled list" >&2

            return 1
        fi

        __ENV_ENABLED="$(echo "$__ENV_ENABLED" | grep -v "|$__ENV_OPTION")"

        if ! echo "$__ENV_ENABLED" > "$ENV_CONFIG/enabled"; then
            echo "env: $__ENV_OPTION: could not keep disabled" >&2

            unset __ENV_OPTION
            __env_clean "$__ENV_OPTION"

            return 1
        fi
    fi

    echo "Please reload your environment for the changes to take effect."
    echo "Some options may leave some traces of themselves until a reload"
    echo "is performed."

    unset __ENV_OPTION
    __env_clean "$__ENV_OPTION"
}

###
# Enables an option.
#
# @param  $1  The name of the option.
#
# @return 0|1 If successfully enabled, `0`. Otherwise, `1`.
##
__env_enable()
{
    if [ "$1" = '' ]; then
        echo "env: option name required" >&2

        return 1
    fi

    __ENV_OPTION="$1"; shift

    if grep "|$__ENV_OPTION" "$ENV_CONFIG/enabled" > /dev/null 2>&1; then
        echo "env: $__ENV_OPTION: already enabled" >&2

        unset __ENV_OPTION

        return 0
    fi

    if ! type "__env_option_${__ENV_OPTION}_enable" > /dev/null 2>&1; then
        if [ ! -f "$ENV_DIR/options/$__ENV_OPTION.sh" ]; then
            echo "env: $__ENV_OPTION: no such option" >&2

            unset __ENV_OPTION

            return 1
        fi

        if ! . "$ENV_DIR/options/$__ENV_OPTION.sh"; then
            echo "env: $__ENV_OPTION: could not be loaded" >&2

            unset __ENV_OPTION

            return 1
        fi

        if ! type "__env_option_${__ENV_OPTION}_enable" > /dev/null 2>&1; then
            echo "env: $__ENV_OPTION: does not have an enabler function" >&2

            unset __ENV_OPTION
            __env_clean "$__ENV_OPTION"

            return 1
        fi
    fi

    if ! "__env_option_${__ENV_OPTION}_enable" "$@"; then
        echo "env: $__ENV_OPTION: could not be enabled" >&2

        unset __ENV_OPTION
        __env_clean "$__ENV_OPTION"

        return 1
    fi

    if [ "$__ENV_PRIORITY" = '' ]; then
        __ENV_PRIORITY=50
    fi

    if [ -f "$ENV_CONFIG/enabled" ]; then
        if ! __ENV_ENABLED="$(cat "$ENV_CONFIG/enabled")"; then
            echo "env: could not read enabled list" >&2

            unset __ENV_OPTION
            __env_clean "$__ENV_OPTION"

            return 1
        fi

        __ENV_ENABLED="$__ENV_ENABLED
$__ENV_PRIORITY|$__ENV_OPTION"
        __ENV_ENABLED="$(echo "$__ENV_ENABLED" | sort)"
    else
        __ENV_ENABLED="$__ENV_PRIORITY|$__ENV_OPTION"
    fi

    if ! echo "$__ENV_ENABLED" > "$ENV_CONFIG/enabled"; then
        echo "env: $__ENV_OPTION: could not keep enabled" >&2

        unset __ENV_OPTION
        __env_clean "$__ENV_OPTION"

        return 1
    fi

    echo "Please reload your environment for the changes to take effect."
    echo "Some options need to be loaded in a specific order to function"
    echo "properly."

    unset __ENV_OPTION
    __env_clean "$__ENV_OPTION"
}

###
# Lists the available options.
##
__env_list()
{
    echo "Available options:"
    echo

    find "$ENV_DIR/options" -name '*.txt' | while read -r FILE; do
        cat "$FILE"
    done
}

################################################################################
# Interface                                                                    #
################################################################################

###
# Provides a user friendly way of managing options.
#
# @param  $1  The command.
# @param  $@  The command arguments.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
option()
{
    case "$1" in
        config)
            shift

            case "$1" in
                get)
                    shift
                    __env_config_get "$@"
                    return $?
                    ;;

                set)
                    shift
                    __env_config_set "$@"
                    return $?
                    ;;

                *)
                    echo "env: $1: invalid config command" >&2

                    return 1
                    ;;
            esac
            ;;

        disable)
            shift
            __env_disable "$@"
            return $?
            ;;

        enable)
            shift
            __env_enable "$@"
            return $?
            ;;

        list)
            shift
            __env_list "$@"
            return $?
            ;;

        *)
            echo "env: $1: invalid command" >&2

            return 1
            ;;
    esac
}

################################################################################
# Initialize                                                                   #
################################################################################

# Ensure we know the path to this directory.
if [ "$ENV_DIR" = '' ]; then
    echo "ENV_DIR: must be defined" >&2

# Initialize the personalization manager.
else
    __env_bootstrap

    unset __env_activate
    unset __env_bootstrap
fi