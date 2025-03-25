#!/bin/sh
################################################################################
# php-build Option                                                             #
#                                                                              #
# This option will manage the installation and activation of php-build as a    #
# phpenv plugin. If php-build is not installed, it will be cloned from the     #
# source.                                                                      #
################################################################################

# shellcheck disable=SC2016

###
# Inititalizes php-build.
##
__env_option_php-build_activate()
{
    : # do nothing
}

###
# Unregisters php-build.
##
__env_option_php-build_disable()
{
    if [ -d "$(phpenv root)/plugins/php-build" ]; then
        if ! rm -Rf "$(phpenv root)/plugins/php-build"; then
            __env_err "php-build: unable to clean up repo"
        fi
    fi
}

###
# Installs and registers php-build.
##
__env_option_php-build_enable()
{
    if ! command -v git > /dev/null; then
        __env_err "php-build: git is required"

        return 1
    fi

    if __env_option_disabled phpenv; then
        __env_err "php-build: phpenv option is required"

        return 1
    fi

    if [ ! -d "$(phpenv root)/plugins/php-build" ]; then
        if ! git clone https://github.com/php-build/php-build.git "$(phpenv root)/plugins/php-build"; then
            __env_err "php-build: unable to install from repo"

            return 1
        fi
    fi
}
