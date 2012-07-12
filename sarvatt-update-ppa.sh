#!/bin/bash
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#
# Automated packaging/uploading script for auto-xorg-git. Based in part off
# of go-update.sh  and ppa-update (c) Tormod Volden.
#
#
# Requires xorg-pkg-tools in the current directory!
# Get it with bzr branch lp:~xorg-edgers/xorg-server/xorg-pkg-tools

###################################################################################################
# TODO: Packages not working with auto-xorg-git because they are not in pkg-xorg
# or have an undefined upstream: Adapt xorg-pkg-tools.lib to find them.
# Not in pkg-xorg: xf86-input-tslib, xf86-input-wacom, xf86-video-omapfb, libxcb
#   libxcb, xcb-proto, xf86-input-glamo
# Undefined upstream branches: xserver-xorg-input-evtouch, xf86-input-dovefb
#   xf86-input-omapfb xf86-input-glamo xserver-xorg-video-ivtvdev
#
# * Provided options to build resultant packages instead of just allowing uploads
#   and building the source packages.
#
# * Merge into auto-xorg-git directly?
#
###################################################################################################
# Attic packages, obsoleted but listed for reference:
# Libs: libxevie, libxfontcache libxkbui libxtrap libxxf86misc
# Protos: xeviev fontcache xtrap
# Drivers:
#  Input: calcomp, digitaledge, dmc, dynapro, elo2300, jamstudio, magellan, magictouch 
#  magictouch palmax magictouch spaceorb summa tek4957 ur98
#  Video: amd, ast, avivo, cyrix, imstt, msc, sunbw2 vga via
###################################################################################################

###################################################################################################
############################### Define these before running! ######################################
###################################################################################################
# Location to upload to, as defined in ~/.dput.cf
PPA=xorg
# Primary distribution to create packages for. Will not have the dist in the version.
DIST=quantal
# Secondary distribution to create packages for, will add ~lucid to the version for the default.
DIST2=precise
# Extra version tag to add. example: libdrm 2.4.20+git20100604.ffffffff-0ubuntu0sarvatt
NAMETAG=0ubuntu0sarvatt

# Set to 1 enable building of package sets. Descriptions of each are below.
CUSTOM_ONE=0
CUSTOM_TWO=0
PROTOS=0
LIBS=0
VIDEO_DEBIAN=0
VIDEO_UBUNTU=0
INPUT_DEBIAN=0
INPUT_UBUNTU=0

# Used for PROTOS, LIBS, VIDEO_DEBIAN, and INPUT_DEBIAN targets, individually customizable below.
DEFAULT_DEBIAN_BRANCH=unstable

# Path to xorg-pkg-tools
XORGPKGTOOLS="$PWD"

# Path to hooks directory, adjustable because different packagers use different hooks.
HOOKDIR=hooks-sarvatt

DEFAULT_OPTS="-r $DIST -H $XORGPKGTOOLS/$HOOKDIR -g -a $NAMETAG"

SEND=
############################################################################################################
# Packages lists for each target, set the variable above to 1 to build the list of packages in the target. #
############################################################################################################
# CUSTOM_ONE: Custom target, usually for things you want to do seperately. Only supports one package.
CUSTOM_ONE_LIST="mesa"
CUSTOM_ONE_OPTS="$DEFAULT_OPTS -d origin/ubuntu -v 8.1 -t ~"

# CUSTOM_TWO: Another custom target, default is set up for building xserver with custom branch options.
CUSTOM_TWO_LIST="xorg-server"
CUSTOM_TWO_OPTS="$DEFAULT_OPTS -d origin/ubuntu -b server-1.12-branch -t +"

# PROTOS: All x11-proto packages with packaging from debian-$PROTO_BRANCH (default unstable)
PROTO_LIST="bigreqs composite core damage dmx dri2 fixes fonts gl input kb print randr record \
render resource scrnsaver video xcmisc xext xf86bigfont xf86dga xf86dri xf86misc xf86vidmode \
xinerama"
PROTO_BRANCH=$DEFAULT_DEBIAN_BRANCH
PROTO_OPTS="$DEFAULT_OPTS -d origin/debian-$PROTO_BRANCH -t +"

# LIBS: Libs to be merged from origin/debian-unstable. Be careful with these,
# because they usually require manual symbol checking and must be built in the proper
# order. Not recommended to have PPA defined if using these, just make the source packages.
LIB_LIST="libxtrans libxau libxdmcp libpciaccess libice libfontenc libx11 libsm libxaw libxext \
libxfixes libxres libxi libxt libxmu libxtst libxdmx libxpm libxrender libxss libxrandr libxxf86dga libxxf86vm \
libxcomposite libxcursor libxdamage libxfont libxinerama libxv libxcomposite libxvmc \
libxkbfile libxp libxpm"
LIB_BRANCH=$DEFAULT_DEBIAN_BRANCH
#LIB_BRANCH=experimental --for  pixman
LIB_OPTS="$DEFAULT_OPTS -d origin/debian-$LIB_BRANCH -t +"

# VIDEO_DEBIAN: Video drivers merged from origin/debian-$D_VID_BRANCH (default: unstable)
D_VID_LIST="apm ark chips cirrus dummy fbdev glide glint i128 i740 mach64 \
neomagic nv r128 rendition s3 s3virge savage siliconmotion sis sisusb \
tdfx tga trident tseng v4l vesa voodoo modesetting openchrome"
#disabled: mga (version conflicts) radeonhd (obsolete)
D_VID_BRANCH=$DEFAULT_DEBIAN_BRANCH
D_VID_OPTS="$DEFAULT_OPTS -d origin/debian-$D_VID_BRANCH -t +"

#VIDEO_UBUNTU: Video drivers to be merged from origin/ubuntu
U_VID_LIST="intel vmware ati nouveau"
U_VID_OPTS="$DEFAULT_OPTS -d origin/ubuntu -t +"

# INPUT_DEBIAN: Input drivers to be merged from origin/debian-$D_INPUT_BRANCH (default: unstable)
# keyboard?
D_INPUT_LIST="acecad aiptek citron elographics fpit hyperpen joystick mouse \
mutouch penmount vmmouse void synaptics keyboard"
D_INPUT_BRANCH=$DEFAULT_DEBIAN_BRANCH
D_INPUT_OPTS="$DEFAULT_OPTS -d origin/debian-$D_INPUT_BRANCH -t +"

# INPUT_UBUNTU: Input drivers to be merged from origin/ubuntu
U_INPUT_LIST="evdev"
# evdev synaptics
U_INPUT_OPTS="$DEFAULT_OPTS -d origin/ubuntu -t +"


# Prepares the package for packaging on DIST2.
# Appends the version in the changelog with ~lucid by default.
chd () {
    head -1 debian/changelog | grep "$1" && return 1
    sed -i "1s/) [^;]*/~$1) $1/" debian/changelog
}

send () {
    notify-send -t $((1000+300*`echo -n $* | wc -w`)) -u low -i gtk-dialog-info "$*" "$*" || return
}

if [ "$CUSTOM_ONE" = "1" ]; then
	send Updating $CUSTOM_ONE_LIST for $DIST
	AOPTS=$CUSTOM_ONE_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p $CUSTOM_ONE_LIST
	cd auto-$CUSTOM_ONE_LIST
	cd $CUSTOM_ONE_LIST
	if chd $DIST2 ; then
		send Updating $CUSTOM_ONE_LIST for $DIST2
		git commit -a -m "$DIST2 version" || true
		debuild -S -i -I -sd
		dput $PPA ../*${DIST2}_source.changes || true
	fi
	cd $XORGPKGTOOLS
fi

if [ "$CUSTOM_TWO" = "1" ]; then
	send Updating $CUSTOM_TWO_LIST for $DIST
	AOPTS=$CUSTOM_TWO_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p $CUSTOM_TWO_LIST
	cd auto-$CUSTOM_TWO_LIST
	cd $CUSTOM_TWO_LIST
	if chd $DIST2 ; then
		send Updating $CUSTOM_TWO_LIST for $DIST2
		git commit -a -m "$DIST2 version" || true
		debuild -S -i -I -sd
		dput $PPA ../*${DIST2}_source.changes || true
	fi
	cd $XORGPKGTOOLS
fi

if [ "$PROTOS" = "1" ]; then
	for a in $PROTO_LIST; do
		send Updating x11proto-$a for $DIST
		AOPTS=$PROTO_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p x11proto-$a
		cd auto-x11proto-$a
		cd x11proto-$a
		if chd $DIST2 ; then
			send Updating x11proto-$a for $DIST2
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

if [ "$LIBS" = "1" ]; then
	for b in $LIB_LIST; do
		send Updating $b for $DIST
		AOPTS=$LIB_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p $b
		cd auto-$b
		cd $b
		if chd $DIST2 ; then
			send Updating $b for $DIST2
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

if [ "$VIDEO_DEBIAN" = "1" ]; then
	for c in $D_VID_LIST; do
		send Updating xserver-xorg-video-$c for $DIST
		AOPTS=$D_VID_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update $c
		cd auto-$c
		cd xserver-xorg-video-$c
		if chd $DIST2 ; then
			send Updating xserver-xorg-video-$c for $DIST2
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

if [ "$VIDEO_UBUNTU" = "1" ]; then
	for d in $U_VID_LIST; do
		send Updating xserver-xorg-video-$d for $DIST
		AOPTS=$U_VID_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update $d
		cd auto-$d
		cd xserver-xorg-video-$d
		if chd $DIST2 ; then
			send Updating xserver-xorg-video-$d for $DIST2
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

if [ "$INPUT_DEBIAN" = "1" ]; then
	for e in $D_INPUT_LIST; do
		send Updating xserver-xorg-input-$e for $DIST
		AOPTS=$D_INPUT_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p xserver-xorg-input-$e
		cd auto-xserver-xorg-input-$e
		cd xserver-xorg-input-$e
		if chd $DIST2 ; then
			send Updating xserver-xorg-input-$e for $DIST2
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

if [ "$INPUT_UBUNTU" = "1" ]; then
	for f in $U_INPUT_LIST; do
		send Updating xserver-xorg-input-$f for $DIST
		AOPTS=$U_INPUT_OPTS PPA=$PPA $XORGPKGTOOLS/ppa-update -p xserver-xorg-input-$f
		cd auto-xserver-xorg-input-$f
		cd xserver-xorg-input-$f
		if chd $DIST2 ; then
			send Updating xserver-xorg-input-$f for $DIST
			git commit -a -m "$DIST2 version" || true
			debuild -S -i -I -sd
			dput $PPA ../*${DIST2}_source.changes || true
		fi
		cd $XORGPKGTOOLS
	done
fi

killall -9 notify-osd
send "All done!"

exit 0
