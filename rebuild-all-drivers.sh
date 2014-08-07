#!/bin/bash

# A script for rebuilding all of the X input and video drivers, such as
# following an xserver update.
#
# Copyright 2011 Canonical, Ltd.
# Authors:  Chris Halse Rogers, Bryce Harrington

#codename="utopic"
codename=$(current-ubuntu-development-codename)

X_INPUT_ABI=$(cut -d, -f 1 /usr/share/xserver-xorg/xinputdep)
X_VIDEO_ABI=$(cut -d, -f 1 /usr/share/xserver-xorg/videodrvdep)

if [ -z "$X_INPUT_ABI" -o -z "$X_VIDEO_ABI" ] ; then
    echo "Current xserver-xorg-dev package must be installed"
    exit 1
fi

if [ -z "$1" ] ; then
    echo "Must specify new minimum xserver version"
    exit 1
fi

echo 

# Grab all the packages depending on the current Xserver video and input ABI.
# There may be some packages which don't have correct dependencies, but there's not much we can do about them.
apt-get source $(grep-aptavail -F Depends -s Package $X_VIDEO_ABI | sed "s/^.*: //g")
apt-get source $(grep-aptavail -F Depends -s Package $X_INPUT_ABI | sed "s/^.*: //g")

rm *.dsc

version=$1

for I in */debian/.. ; do
   (cd $I &&
# Add versioned build-dependency on new Xserver.
       sed -i -r "s/xserver-xorg-dev([[:space:]]*\(>=? 2:1(\.[[:digit:]]*)*([~+]git[[:digit:]]*(\.(.){8})?)?~?(-[[:digit:]]+(ubuntu[[:digit:]]+)?~?)?\))?/xserver-xorg-dev (>= ${version})/g" debian/control
       dch -l "+ppa" "Rebuild to pick up new Xserver dependencies" --distribution ${codename} &&
       dpkg-buildpackage -S)
done

echo "All *.changes ready to be uploaded"

# TODO: Pause and let the user doublecheck things
#for I in *.changes ; do
#   dput ubuntu $I
#done
