#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

# ./finder-app/manual-linux.sh /home/fabio/Documents/studies/linux-studies/linux-assignment-3-part-2/aeld

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR} && cd "$OUTDIR"

if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} ${OUTDIR} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    echo "Changing file ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.lex.c"
    # sed -i 's/YYLTYPE yylloc/extern &/' ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.lex.c
    # git apply ./patch.diff ${OUTDIR}/${KERNEL_REPO}/scripts/dtc/dtc-lexer.lex.c
    # git apply ./patch.diff
    # YYLTYPE yylloc
    # 
    # /home/fabio/Documents/studies/linux-studies/linux-assignment-3-part-2/aeld/linux-stable/scripts/dtc/dtc-lexer.lex.c  
    # git diff --no-index /path/to/foo /path/to/bar


    # TODO: Add your kernel build steps here
    echo $PATH
    #make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    sed -i 's/YYLTYPE yylloc/extern &/' ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.lex.c
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
fi
#exit 1
echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p "${OUTDIR}/rootfs/bin/"
mkdir -p "${OUTDIR}/rootfs/dev/"
mkdir -p "${OUTDIR}/rootfs/etc/"
mkdir -p "${OUTDIR}/rootfs/lib/"
mkdir -p "${OUTDIR}/rootfs/proc/"
mkdir -p "${OUTDIR}/rootfs/sys/"
mkdir -p "${OUTDIR}/rootfs/sbin/"
mkdir -p "${OUTDIR}/rootfs/tmp/"
mkdir -p "${OUTDIR}/rootfs/usr/bin/"
mkdir -p "${OUTDIR}/rootfs/usr/sbin/"
mkdir -p "${OUTDIR}/rootfs/var/"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd ${OUTDIR}/busybox && git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu-
#busybox --install -s "${OUTDIR}/rootfs/bin/"
make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- CONFIG_PREFIX="${OUTDIR}/rootfs/" install

chmod 700 ${OUTDIR}/rootfs/bin/busybox


# TODO: Add library dependencies to rootfs
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Make device nodes
mkdir -p ${OUTDIR}/rootfs/dev

# TODO: Clean and build the writer utility

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO: Chown the root directory
chown root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
