#!/bin/sh
################################################################################
# macOS Dock Option                                                            #
#                                                                              #
# This script provides a few customization options for the macOS dock on       #
# versions of the operating system that are supported.                         #
################################################################################

# shellcheck disable=SC3043

###
# Defines the dock command.
##
__env_option_dock_activate()
{
    # Create a function to customize the dock.
    dock()
    {
        echo "dock called"
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
