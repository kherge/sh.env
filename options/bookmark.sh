#!/bin/sh
################################################################################
# Bookmark Manager                                                             #
#                                                                              #
# Manages aliases for file system paths. This allows users to memorize simpler #
# alias names instead of long paths, reducing human error (and frustration).   #
################################################################################

# shellcheck disable=SC3043

################################################################################
# Option Handlers                                                              #
################################################################################

###
# Enables the option by defining a new command.
##
__env_option_bookmark_activate()
{
    ###
    # Provides an interface for managing and using bookmarks.
    #
    # @param  $1  The alias.
    # @param  $2  The path.
    #
    # @return 0|1 If successful, `0`. Otherwise, `1`.
    #
    # shellcheck disable=SC2317
    ##
    bm()
    {
        local ALIAS_NAME="$1"
        local ALIAS_PATH="$2"

        if [ "$ALIAS_NAME" = '' ]; then
            cat - >&2 <<'HERE'
Usage: bm ALIAS PATH|OPTIONS
Manages aliases and changes directories.

This command lets you define a simpler alias for a longer path, and then use
that alias instead of the path when changing a directory. Setting a path for
an existing alias will simply replace the path the alias resolves to. The
alias path is evaluated before it is used to change directories in order to
support dynamic values. To support this evaluation, be sure to enclose
the path in single quotes (e.g. '$HOME/my/path').

ARGUMENTS

    NAME  The command to invoke.
    PATH  The path to be managed.

OPTIONS

    -d, --delete  Deletes the alias.

USAGE

    bm project '$HOME/path/to/project'

        This will define a "project" alias for the specified path.

    bm project

        This will evaluate the path for the "project" alias and change the
        current directory to it. The output and status code will be the same
        as `cd`.

    bm project -d
    bm project --delete

        This will delete the "project" alias.

    bm project -l
    bm project --list

        This will list the aliases available.
HERE
        fi

        # Get the aliases.
        if ! ALIASES="$(__env_config_get bookmark.aliases)"; then
            __env_err "env: bookmark: could not get aliases"

            return 1
        fi

        # Delete the alias.
        if [ "$ALIAS_PATH" = '-d' ] || [ "$ALIAS_PATH" = '--delete' ]; then
            ALIASES="$(echo "$ALIASES" | grep -vF "$ALIAS_NAME|")"

            if ! __env_config_set bookmark.aliases "$ALIASES"; then
                return 1
            fi

        # List the aliases.
        elif [ "$ALIAS_NAME" = '-l' ] || [ "$ALIAS_NAME" = '--list' ]; then
            local MAX_SIZE=0

            while read -r COMBO; do
                CURRENT_SIZE=$(echo "$COMBO" | cut -d\| -f1 | wc -m)

                if [ $CURRENT_SIZE -gt $MAX_SIZE ]; then
                    MAX_SIZE=$((CURRENT_SIZE - 1))
                fi
            done < <(echo "$ALIASES")

            echo "$ALIASES" | sort | while read -r COMBO; do
                if [ "$COMBO" = '' ]; then
                    continue
                fi

                printf "%${MAX_SIZE}s  %s\n" \
                    "$(echo "$COMBO" | cut -d\| -f1)" \
                    "$(echo "$COMBO" | cut -d\| -f2)"
            done

        # Define the alias.
        elif [ "$ALIAS_PATH" != '' ]; then
            ALIASES="$(echo "$ALIASES" | grep -vF "$ALIAS_NAME|")"
            ALIASES="$ALIASES
$ALIAS_NAME|$ALIAS_PATH"
            ALIASES="$(echo "$ALIASES" | sort)"

            if ! __env_config_set bookmark.aliases "$ALIASES"; then
                return 1
            fi

        # Change directory.
        else
            ALIAS="$(echo "$ALIASES" | grep -F "$ALIAS_NAME|" | head -1)"

            if [ "$ALIAS" = '' ]; then
                __env_err "env: bookmark: no such alias"

                return 1
            fi

            ALIAS_PATH="$(echo "$ALIAS" | cut -d\| -f2)"
            ALIAS_PATH="$(eval "echo \"$ALIAS_PATH\"")"

            cd "$ALIAS_PATH" || return
        fi
    }
}

###
# Disables the bookmark option.
##
__env_option_bookmark_disable()
{
    # Clean up our runtime.
    unset bm
}
