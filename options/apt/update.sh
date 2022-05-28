#!/bin/sh

echo 'Updating sh.env apt package list...'

set -e

apt-mark showmanual > "$1"
