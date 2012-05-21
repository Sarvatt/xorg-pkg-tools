#!/bin/bash

# Simple script meant for reapplying patches after the big
# X.org "one style to fit them all" change

# Usage: patch-x-indent.sh BREAKCOMMIT patchfile
INDENT=`which gnuindent || which gindent || which indent`

if [ -z "${INDENT}" ] ; then
    echo "Could not find indent, sorry..." >&2
    exit 1
fi

if [ ! -r "$2" ]; then
	echo Usage: "$0" BREAKCOMMIT patchfile
	exit 1
fi

git checkout --detach $1^
patch -Np1 -i $2 || (echo Dropping you in a subshell to fix rejects in $(basename $2); bash)

# Run the x-indent-all.sh script
if git ls-files | grep '\.[chm]$' | xargs \
$INDENT -linux -bad -bap -blf -bli0 -cbi0 -cdw -nce -cs -i4 -lc80 -psl -nbbo \
    -nbc -psl -nbfda -nut -nss -T pointer -T ScreenPtr -T ScrnInfoPtr -T pointer \
    -T DeviceIntPtr -T DevicePtr -T ClientPtr -T CallbackListPtr \
    -T CallbackProcPtr -T OsTimerPtr -T CARD32 -T CARD16 -T CARD8 \
    -T INT32 -T INT16 -T INT8 -T Atom -T Time -T WindowPtr -T DrawablePtr \
    -T PixmapPtr -T ColormapPtr -T CursorPtr -T Font -T XID -T Mask \
    -T BlockHandlerProcPtr -T WakeupHandlerProcPtr -T RegionPtr \
    -T InternalEvent -T GrabPtr -T Timestamp -T Bool -T TimeStamp \
    -T xEvent -T DeviceEvent -T RawDeviceEvent -T GrabMask -T Window \
    -T Drawable -T FontPtr -T CallbackPtr -T XIPropertyValuePtr \
    -T GrabParameters -T deviceKeyButtonPointer -T TouchOwnershipEvent \
    -T xGenericEvent -T DeviceChangedEvent -T GCPtr -T BITS32 \
    -T xRectangle -T BoxPtr -T RegionRec -T ValuatorMask -T KeyCode \
    -T KeySymsPtr -T XkbDescPtr -T InputOption -T XI2Mask -T DevUnion \
    -T DevPrivateKey -T DevScreenPrivateKey -T PropertyPtr -T RESTYPE \
    -T XkbAction -T XkbChangesPtr -T XkbControlsPtr -T PrivatePtr -T pmWait \
    -T _XFUNCPROTOBEGIN -T _XFUNCPROTOEND -T _X_EXPORT; then
	git diff $1 | tee $2.out
fi

