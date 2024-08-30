#!/bin/sh
################################################################################
# macOS Dock Option                                                            #
#                                                                              #
# This script provides a few customization options for the macOS dock on       #
# versions of the operating system that are supported.                         #
################################################################################

# shellcheck disable=SC3043

################################################################################
# Option Handlers                                                              #
################################################################################

###
# Defines the dock command.
##
__env_option_dock_activate()
{
    # Create a function to customize the dock.
    dock()
    {
        local COMMAND="$1"; shift

        case "$COMMAND" in
            ""|help)
                cat - >&2 <<'HERE'
Usage: dock COMMAND
Customizes the macOS dock.

COMMANDS

    add-spacer  SIDE  Adds a spacer tile to the dock.
HERE
                ;;

            add-spacer)
                __env_option_dock_add_spacer "$@"
                return $?
                ;;

            *)
                __env_err "dock: $COMMAND: invalid command"

                return 1
                ;;

        esac
    }
}

###
# Removes the dock command.
##
__env_option_dock_disable()
{
    # Clean up our runtime.
    unset dock
}

###
# Checks if the `defaults` command is available.
#
# @return 0|1 Returns `0` if successfully enabled, or `1` if not.
##
__env_option_dock_enable()
{
    # Make sure that the needed CLI utility is available.
    if ! command -v defaults > /dev/null; then
        __env_err 'dock: defaults is required'

        return 1
    fi
}

################################################################################
# Option Internals                                                             #
################################################################################

###
# Adds a spacer to the dock.
#
# @param $1 The side to add the spacer to.
##
__env_option_dock_add_spacer()
{
    # Handle the small option.
    local TILE_TYPE="spacer-tile"

    if [ "$1" = '-s' ] || [ "$1" = '--small' ]; then
        shift

        TILE_TYPE="small-spacer-tile"
    fi

    # Make sure a valid side was specified.
    case "$1" in
        ""|help)
                cat - >&2 <<'HERE'
Usage: dock add-spacer [OPTIONS] SIDE
Adds a spacer to the dock

SIDE

    apps  Adds a spacker to the applications side of the dock.
    docs  Adds a spacer to the documents side of the dock.

OPTIONS

    -s, --small  Uses a smaller space instead of a normal sized one.

HERE

                return 0
                ;;

        apps)

            # Add a spacer to the apps side of the dock.
            defaults write com.apple.dock persistent-apps -array-add "{tile-data={}; tile-type=\"$TILE_TYPE\";}"

            ;;

        docs)

            # Add a spacer to the documents side of the dock.
            defaults write com.apple.dock persistent-others -array-add "{tile-data={}; tile-type=\"$TILE_TYPE\";}"

            ;;

        *)
            __env_err 'dock: side required'

            return 1
    esac

    # Restart the dock.
    killall Dock
}
