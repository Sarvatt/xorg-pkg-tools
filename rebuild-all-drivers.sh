#!/bin/bash

# A script for rebuilding all of the X input and video drivers, such as
# following an xserver update.
#
# Copyright 2011 Canonical, Ltd.
# Authors:  Chris Halse Rogers, Bryce Harrington

# TODO: Make *sure* to wait until all of the xserver builds are done
#       (Including arm and everything else)

# TODO: Don't forget about indirect dependencies of -video-all, such as -mach64 and -r128

# TODO: Stage all this in a xorg-staging PPA

# Verify system is the current development ubuntu (requires python-launchpadlib-toolkit)
codename=$(current-ubuntu-development-codename)

if [ $(lsb_release -cs) != "$codename" ] ; then
    echo "This script must be run on a $codename system"
    exit 1
fi

apt-get source $(apt-cache show xserver-xorg-video-all | grep Depends: | sed s/Depends://g | sed s/,//g)
apt-get source $(apt-cache show xserver-xorg-input-all | grep Depends: | sed s/Depends://g | sed s/,//g)

for I in * ; do
   [ -d $I ] && (cd $I && dch --rebuild "Rebuild against Xserver 1.10" --distribution ${codename} && dpkg-buildpackage -S)
done

echo "All *.changes ready to be uploaded"

#<vorlon> bryyce: well, armel got hit by the no-change driver rebuilds not having versioned build-dependencies on the new xserver# -dev... :)
# bryyce: when you're doing such ABI rebuilds, could you please bump the versioned build-dep?
# TODO:  Above seems hard to do automatically, and would require parsing/rewriting the control file...

# TODO: Pause and let the user doublecheck things
#for I in *.changes ; do
#   dput ubuntu $I
#done
