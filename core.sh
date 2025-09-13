#!/bin/sh

# shellcheck disable=SC1090
# shellcheck disable=SC3043

# Define the path to the configuration folder.
export __ENV_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}/env"

# Define the path to the features folder.
export __ENV_FEATURES_DIR="$__ENV_DIR/features"

# @description Prints the arguments to STDERR if debugging is enabled.
#
# @arg $@ An argument to print.
#
# @stderr The given arguments.
if [ "${__ENV_DEBUG:-0}" -eq 1 ]; then
    __env_debug()
    {
        echo "env [debug]:" "$@" >&2
    }
else
    __env_debug()
    {
        : # no-op
    }
fi

# @description Prints the arguments to STDERR.
#
# @arg $@ An argument to print.
#
# @stderr The given arguments.
__env_error()
{
    echo env: "$@" >&2
}

# @description Returns the value for a feature configuration setting.
#
# If the configuration file does not exist, nothing will be echoed and no error
# will be produced. A configuration file that does not exist is treated the as
# if the configuration file is empty.
#
# @arg $1 The name of the feature.
# @arg $2 The name of the setting.
#
# @stderr If the value could not be retrieved.
# @stdout The value of the configuration setting.
#
# @exitcode 0 The value was successfully retrieved.
# @exitcode 1 The value could not be retrieved.
__env_get()
{
    local CONFIG_DIR="$__ENV_CONFIG_DIR/$1"
    local CONFIG_FILE="$CONFIG_DIR/$2"

    if [ -f "$CONFIG_FILE" ]; then
        if ! cat "$CONFIG_FILE"; then
            __env_error "$1: could not read file: $CONFIG_FILE"

            return 1
        fi
    else
        __env_debug "no config file for: $CONFIG_FILE"
    fi
}

# @description Loads all of the enabled features.
__env_load()
{
    local FEATURE_LIST="$__ENV_CONFIG_DIR/core/on"

    # Load features if any are enabled.
    if [ -f "$FEATURE_LIST" ]; then
        while IFS= read -r FEATURE; do
            local FEATURE_FILE="$__ENV_FEATURES_DIR/$FEATURE.sh"

            if [ -f "$FEATURE_FILE" ]; then
                __env_debug "loading: $FEATURE"

                . "$FEATURE_FILE"
            else
                __env_debug "no such feature: $FEATURE"
            fi
        done < "$FEATURE_LIST"
    else
        __env_debug "no features enabled"
    fi

    # Self destruct.
    unset -f __env_load
}

# @description Forgets that a feature was turned on.
#
# @arg $1 The name of the feature.
#
# @exitcode 0 The feature was successfully marked as off.
# @exitcode 1 The feature could not be marked as off.
__env_off()
{
    local FEATURE="$1"
    local FEATURES=

    if ! FEATURES="$(__env_get core on)"; then
        return 1
    fi

    # Remove the feature from the list.
    FEATURES="$(printf "%s" "$FEATURES" | grep -v -x "$FEATURE" | sort -u)"

    # Save the changed list.
    __env_set core on "$FEATURES"

    return $?
}

# @description Remembers that a feature was turned on.
#
# @arg $1 The name of the feature.
#
# @exitcode 0 The feature was successfully marked as on.
# @exitcode 1 The feature could not be marked as on.
__env_on()
{
    local FEATURE="$1"
    local FEATURES=

    if ! FEATURES="$(__env_get core on)"; then
        return 1
    fi

    # Add the feature to the list.
    FEATURES="$(printf "%s\n%s" "$FEATURES" "$FEATURE" | sort -u | grep -v -x '^$')"

    # Save the changed list.
    __env_set core on "$FEATURES"

    return $?
}

# @description Sets the value for a feature configuration setting.
#
# If the value for the setting is "-", then STDIN will be read and used as
# the value instead. If no value is provided in STDIN, it may cause the script
# to hang.
#
# If the value is an empty string, or if no value is provided, the file for the
# configuration setting will instead be deleted.
#
# @arg $1 The name of the feature.
# @arg $2 The name of the setting.
# @arg $3 The value of the setting.
#
# @stderr If the value could not be set.
#
# @exitcode 0 The value was successfully set.
# @exitcode 1 The value could not be set.
__env_set()
{
    local CONFIG_DIR="$__ENV_CONFIG_DIR/$1"
    local CONFIG_FILE="$CONFIG_DIR/$2"
    local VALUE="$3"

    if [ ! -d "$CONFIG_DIR" ]; then
        if ! mkdir -p "$CONFIG_DIR"; then
            __env_error "$1: could not create directory: $CONFIG_DIR"

            return 1
        fi
    fi

    if [ "$VALUE" = "-" ]; then
        cat - > "$CONFIG_FILE"
    elif [ "$VALUE" != "" ]; then
        printf "%s" "$VALUE" > "$CONFIG_FILE"
    elif [ -f "$CONFIG_FILE" ]; then
        rm "$CONFIG_FILE"
    fi

    return $?
}

# @description Manages the process of interacting with a shell feature.
feature()
{
    local FEATURE="$1"

    # Make sure feature is specified.
    if [ -z "$FEATURE" ]; then

        # Display usage with list of available features.
        echo "Usage: feature FEATURE COMMAND [...]" >&2
        echo "Manages the configuration of a shell customization feature." >&2
        echo >&2
        echo "FEATURE" >&2
        echo >&2
        echo "The following features are available:" >&2
        echo >&2

        local FILE=
        local NAME=
        
        find "$__ENV_FEATURES_DIR" -type f -name '*.sh' | while read -r FILE; do
            NAME="$(basename "$FILE" .sh)"

            echo "    $NAME" >&2
        done

        echo >&2
        echo "COMMAND" >&2
        echo >&2
        echo "   help  Display the feature's help message." >&2
        echo "    off  Disables the feature." >&2
        echo "     on  Enables the feature." >&2
        echo >&2
        echo "Some features may offer additional commands." >&2
        echo >&2
        echo "    feature example help" >&2
        echo >&2
        echo >&2

        return 1
    fi

    # Drop the name so we can forward the arguments.
    shift

    # Check if the feature is already loaded.
    local FEATURE_FUNCTION="__env_feature_$FEATURE"

    if ! type "$FEATURE_FUNCTION" > /dev/null; then

        # Make sure the feature exists.
        if [ ! -f "$__ENV_FEATURES_DIR/$FEATURE.sh" ]; then
            __env_error "no such feature"

            return 1
        fi

        # Load the feature script.
        if ! . "$__ENV_FEATURES_DIR/$FEATURE.sh"; then
            __env_error "unable to load feature"

            return 1
        fi
    fi

    # Forward arguments to the main feature function.
    "$FEATURE_FUNCTION" "$@"
}
