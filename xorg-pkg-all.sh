#!/bin/bash

RELEASE=gutsy

# TODO:  These lists ought to be wget'ed off of git.debian.org

LIB_PACKAGES="\
libdmx \
libdrm \
libfontenc \
libfs \
libice \
libpciaccess \
libsm \
libx11 \
libxau \
libxaw \
libcomposite \
libxcursor \
libxdamage \
libxdmcp \
libxevie \
libxext \
libxfixes \
libxfont \
libxfontcache \
libxi \
libxinerama \
libxkbfile \
libxkbui \
libxmu \
libxp \
libxpm \
libxprintapputil \
libxprintutil \
libxrandr \
libxrender \
libxres \
libxt \
libxtrap \
libxtst \
libxv \
libxvmc \
libxxf86dga \
libxxf86misc \
libxxf86vm \
mesa \
pixman \
xft \
xtrans"

PROTO_PACKAGES="\
x11proto-bigreqs \
x11proto-composite \
x11proto-core \
x11proto-damage \
x11proto-dmx \
x11proto-evie \
x11proto-fixes \
x11proto-fontcache \
x11proto-fonts \
x11proto-gl \
x11proto-input \
x11proto-kb \
x11proto-print \
x11proto-randr \
x11proto-record \
x11proto-render \
x11proto-resource \
x11proto-scrnsaver \
x11proto-trap \
x11proto-video \
x11proto-xcmisc \
x11proto-xext \
x11proto-xf86bigfont \
x11proto-xf86dga \
x11proto-xf86dri \
x11proto-xf86misc \
x11proto-xf86vidmode \
x11proto-xinerama"

# These packages don't come from X.org upstream
UNKNOWN="\
libxss"


PACKAGES="$PROTO_PACKAGES $LIB_PACKAGES"
DEST="/srv/XorgAutoPackage"
TAG="0ubuntu0bwh"

function auto_xorg_git() {
    package=$1

    LOGNUM=$(( LOGNUM + 1 ))
    ./auto-xorg-git -fn \
        $DROP_DEBIAN_PATCHES \
        $MERGE_STRATEGY \
        -p $package \
        -a $TAG \
        -d $DEBIANREPO \
        -r $RELEASE \
        -w $DEST \
        > $DEST/$package.$LOGNUM.log 2>&1
}

for PKG in $PACKAGES; do
    LOGNUM=0

    # Merge from debian experimental
    DROP_DEBIAN_PATCHES=""
    DEBIANREPO="origin/debian-experimental"
    MERGE_STRATEGY=""
    if auto_xorg_git $PKG ; then
        echo "OKAY:  $PKG in $DEBIANREPO"
        continue
    fi

    # Merge from debian unstable
    DROP_DEBIAN_PATCHES=""
    DEBIANREPO="debian-unstable"
    MERGE_STRATEGY=""
    if auto_xorg_git $PKG ; then
        echo "OKAY:  $PKG in $DEBIANREPO"
        continue
    fi

    # Try debian experimental, but drop patches
    DROP_DEBIAN_PATCHES="-D"
    DEBIANREPO="origin/debian-experimental"
    MERGE_STRATEGY=""
    if auto_xorg_git $PKG ; then
        echo "OKAY:  $PKG in $DEBIANREPO, dropping Debian patches"
        continue
    fi

    # Try debian unstable, using resolve strategy
    DROP_DEBIAN_PATCHES=""
    DEBIANREPO="debian-unstable"
    MERGE_STRATEGY="-S resolve"
    if auto_xorg_git $PKG ; then
        echo "OKAY:  $PKG in $DEBIANREPO, using merge strategy 'recursive'"
        continue
    fi

    # Try debian unstable, dropping patches
    DROP_DEBIAN_PATCHES="-D"
    DEBIANREPO="debian-unstable"
    MERGE_STRATEGY=""
    if auto_xorg_git $PKG ; then
        echo "OKAY:  $PKG in $DEBIANREPO, dropping Debian patches"
        continue
    fi

    echo "FAIL:  $PKG packaging"
done

