#!/bin/sh
################################################################################
# APT Tracker                                                                  #
#                                                                              #
# This option will wrap the `apt` command so that a package list is maintained #
# after packages are installed or removed. If this option is activated after a #
# container has been created, the packages in the list will be automatically   #
# installed.                                                                   #
################################################################################

# shellcheck disable=SC2016
# shellcheck disable=SC2145
# shellcheck disable=SC2155
# shellcheck disable=SC3043

###
# Installs missing packages and creates the `apt` wrapper.
##
__env_option_apt_activate()
{
    # Install packages if necessary.
    if ! __env_option_apt_check_tag; then
        return 1
    fi
}

###
# Removes the `apt` wrapper.
##
__env_option_apt_disable()
{
    if ! sudo rm /etc/apt/apt.conf.d/90shenv; then
        __env_err "apt: could not remove apt hook"

        return 1
    fi

    unset __env_option_apt_check_tag
    unset __env_option_apt_has_tag
    unset __env_option_apt_install_hook
    unset __env_option_apt_install_list
    unset __env_option_apt_set_tag
}

###
# Generates the initial package list and tags the container as not new.
##
__env_option_apt_enable()
{
    # Make sure the apt.conf directory exists.
    if [ ! -d /etc/apt/apt.conf.d/ ]; then
        __env_err "apt: could not find apt.conf.id/"

        return 1
    fi

    # Install the hook.
    if ! __env_option_apt_install_hook; then
        return 1
    fi

    # Make sure that apt-mark is available.
    if ! command -v apt-mark > /dev/null; then
        __env_err "apt: apt-mark is required"

        return 1
    fi

    # Set the current package list.
    if ! "$ENV_DIR/options/apt/update.sh" "$ENV_CONFIG/apt.list"; then
        __env_err "apt: unable to create package list"

        return 1
    fi

    # Set the container tag.
    if ! __env_option_apt_has_tag && ! __env_option_apt_set_tag; then
        return 1
    fi
}

################################################################################
# APT Tracker Internals                                                        #
################################################################################

###
# Checks if the container tag exists.
#
# If the container tag does not exist.
##
__env_option_apt_check_tag()
{
    if ! __env_option_apt_has_tag; then
        __env_err "apt: new container detected, installing remembered packages..."

        if __env_option_apt_install_list && \
           __env_option_apt_set_tag; then
            return 0
        fi

        return 1
    fi
}

###
# Checks if this container has the tag file.
##
__env_option_apt_has_tag()
{
    if [ -f "/var/lib/sh.env/apt" ]; then
        return 0
    fi

    return 1
}

###
# Creates and installs the apt hook to track packages.
##
__env_option_apt_install_hook()
{
    local SCRIPT="DPkg::Post-Invoke {\"$ENV_DIR/options/apt/update.sh $ENV_CONFIG/apt.list\";};"

    if ! sudo sh -c "echo '$SCRIPT' > /etc/apt/apt.conf.d/90shenv"; then
        __env_err "apt: unable to install apt hook"

        return 1
    fi
}

###
# Installs the packages found in the list.
##
__env_option_apt_install_list()
{
    if ! sudo xargs -a "$ENV_CONFIG/apt.list" apt-get install -y; then
        __env_err "apt: failed to install packages"

        return 1
    fi
}

###
# Creates a file to tag the container as not new.
##
__env_option_apt_set_tag()
{
    if ! sudo sh -c "mkdir -p /var/lib/sh.env && touch /var/lib/sh.env/apt"; then
        __env_err "apt: could not create tag file"

        return 1
    fi
}
