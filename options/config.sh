#!/bin/sh
################################################################################
# Configuration Settings Option                                                #
#                                                                              #
# Provides the ability to directly interact with the configuration settings    #
# used by th different options. This is a useful debugging tool, and some      #
# options may even require its use for more advanced functionality.            #
################################################################################

###
# Defines the interface function for the user.
##
__env_option_config_activate()
{
    ###
    # Provides an interface in which the user can manage the settings.
    ##
    config()
    {
        local COMMAND="$1"; shift

        case "$COMMAND" in
            ""|-h)
                cat - >&2 <<'HERE'
Usage: config [COMMAND]
Manages option configuration settings.

ARGUMENTS

    COMMAND  The command to invoke.

COMMANDS

    get   Prints the value of a configuration setting.
    list  Lists all available configuration settings and their values.
    set   Sets the value of a configuration setting.
HERE
                ;;

            get)
                __env_option_config_get "$@"
                return $?
                ;;

            list)
                __env_option_config_list "$@"
                return $?
                ;;

            set)
                __env_option_config_set "$@"
                return $?
                ;;

            *)
                __env_err "config: $COMMAND: invalid command"

                return 1
                ;;
        esac
    }
}

###
# Cleans up.
##
__env_option_config_disable()
{
    # Clean up the runtime.
    unset __env_option_config_get
    unset __env_option_config_list
    unset __env_option_config_set
}

################################################################################
# Option Internals                                                             #
################################################################################

###
# Prints the complete value of a configuration setting.
#
# @param  $1  The name of the setting.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_config_get()
{
    local NAME="$1"

    if [ "$NAME" = '' ]; then
        __env_err "config: setting name required"

        return 1
    fi

    __env_config_get "$NAME"

    return $?
}

###
# Prints the list of available options and parts of their values.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_config_list()
{
    local LINES
    local NAME
    local NAME_LENGTH=0
    local TEMP_FILE
    local VALUE
    local VALUE_LENGTH

    if ! TEMP_FILE="$(mktemp)"; then
        __env_err "config: could not create temp file"

        return 1
    fi

    if ! ls -1 "$ENV_CONFIG" | sort > "$TEMP_FILE"; then
        __env_err "config: could not list avavilable settings"

        return 1
    fi

    while read NAME; do
        if [ ${#NAME} -gt $NAME_LENGTH ]; then
            NAME_LENGTH=${#NAME}
        fi
    done < "$TEMP_FILE"

    NAME_LENGTH=$((NAME_LENGTH + 1))
    VALUE_LENGTH=$((75 - $NAME_LENGTH))

    while read NAME; do
        LINES="$(wc -l "$ENV_CONFIG/$NAME" | awk '{print $1}')"
        VALUE="$(cat "$ENV_CONFIG/$NAME" | head -1)"

        if [ ${#VALUE} -gt $VALUE_LENGTH ]; then
            VALUE="$(echo "$VALUE" | cut -b 1-$VALUE_LENGTH) [...]"
        elif [ $LINES -gt 1 ]; then
            VALUE="$(printf "%-${VALUE_LENGTH}s" "$VALUE") [top]"
        fi

        printf "%${NAME_LENGTH}s = %s\n" "$NAME" "$VALUE"
    done < "$TEMP_FILE"

    rm "$TEMP_FILE"
}

###
# Sets the value of a configuration setting.
#
# @param  $1  The name of the setting.
# @param  $2  The new value of the setting.
#
# @return 0|1 If successful, `0`. Otherwise, `1`.
##
__env_option_config_set()
{
    local NAME="$1"
    local VALUE="$2"

    if [ "$NAME" = '' ]; then
        __env_err "config: setting name required"

        return 1
    fi

    if [ "$VALUE" = '-' ]; then
        VALUE="$(cat -)"
    fi

    __env_config_set "$NAME" "$VALUE"

    return $?
}
