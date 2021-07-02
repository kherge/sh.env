#!/bin/sh
################################################################################
# An Example Option                                                            #
#                                                                              #
# This script provides an example of how an option script should be created    #
# for the environment personalizer. The script also attempts to define a set   #
# of best practices in code.                                                   #
################################################################################

###
# Activates the functionality offered by the option.
#
# This function is invoked when a new environment is being prepared for the
# shell. Any functionality that this option is intended to provided will be
# made handled or made available by this function. The function should not:
#
# - exit, only return (return value is ignored)
# - prompt the user for any input
# - print any output, unless to inform the user of an unrecoverable error
##
__env_option_example_activate()
{
    # Increment the number of times the option has been activated.
    if ! __EXAMPLE_COUNT="$(__env_config_get example.count)"; then
        return 1
    fi

    __EXAMPLE_COUNT=$((__EXAMPLE_COUNT + 1))

    if ! __env_config_set example.count $__EXAMPLE_COUNT; then
        return 1
    fi

    # Create a function to print our stats.
    example()
    {
        echo "Enabled on: $(__env_config_get example.enabled)"
        echo "    Loaded: $(__env_config_get example.count) times"
    }
}

###
# Processes the disabling of the option.
#
# This function is invoked when the option has been requested to be disabled.
# The function will be forwarded any additional arguments that have been
# provided to the `option disable example ARGS...` command. The function can be
# used to perform any cleanup operations that are necessary.
#
# @param $@ The additional arguments.
#
# @return 0|1 Returns `0` if successfully disabled, or `1` if not.
##
__env_option_example_disable()
{
    # Clean up our settings.
    if ! __env_config_set example.count ""; then
        return 1
    fi

    if ! __env_config_set example.enabled ""; then
        return 1
    fi
}

###
# Processes the enabling of the option.
#
# This function is invoked when the option has been requested to be enabled. The
# function will be forwarded any additional arguments that have been provided to
# the `option enable example ARGS...` command. The function can be used to make
# any preparations or sanity checks that are necessary.
#
# @param $@ The additional arguments.
#
# @return 0|1 Returns `0` if successfully enabled, or `1` if not.
##
__env_option_example_enable()
{
    # By default, the priority of an option is 50. Let's change that to 00 for
    # this script so it is one of the first to load.
    __ENV_PRIORITY=00

    # Set some default values.
    if ! __env_config_set example.count 0; then
        return 1
    fi

    if ! __env_config_set example.enabled "$(date)"; then
        return 1
    fi
}