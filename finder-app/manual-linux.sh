#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

# ./finder-app/manual-linux.sh /home/fabio/Documents/studies/linux-studies/linux-assignment-3-part-2/aeld

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# KERNEL_VERSION=v5.1.10
KERNEL_VERSION=v6.1.14
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
TOOLCHAIN_PATH=/home/fabio/Documents/studies/linux-studies/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/

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
	git clone ${KERNEL_REPO} ${OUTDIR}/linux-stable --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
  
    # TODO: Add your kernel build steps here
    echo $PATH
    make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all
fi
echo "Adding the Image in outdir"
cp -r ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}
if [ -e ${OUTDIR}/Image ]; then
    echo "Image files copied to ${OUTDIR}/Image"
else
    echo "couldn't copy image files into ${OUTDIR}/Image"
    exit 1
fi

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
ROOTFS=${OUTDIR}/rootfs
mkdir -p "${OUTDIR}/rootfs/bin/"
mkdir -p "${OUTDIR}/rootfs/dev/"
mkdir -p "${OUTDIR}/rootfs/etc/"
mkdir -p "${OUTDIR}/rootfs/home/"
mkdir -p "${OUTDIR}/rootfs/lib/"
mkdir -p "${OUTDIR}/rootfs/lib64/"
mkdir -p "${OUTDIR}/rootfs/proc/"
mkdir -p "${OUTDIR}/rootfs/sbin/"
mkdir -p "${OUTDIR}/rootfs/sys/"
mkdir -p "${OUTDIR}/rootfs/tmp/"
mkdir -p "${OUTDIR}/rootfs/usr/bin/"
mkdir -p "${OUTDIR}/rootfs/usr/sbin/"
mkdir -p "${OUTDIR}/rootfs/usr/lib/"
mkdir -p "${OUTDIR}/rootfs/var/"
mkdir -p "${OUTDIR}/rootfs/var/log/"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd ${OUTDIR}/busybox && git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}
#busybox --install -s "${OUTDIR}/rootfs/bin/"
make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX="${OUTDIR}/rootfs/" install

chmod 700 ${OUTDIR}/rootfs/bin/busybox


# TODO: Add library dependencies to rootfs
echo "Library dependencies"
# ${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
# ${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

sudo cp ${TOOLCHAIN_PATH}/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
sudo ln -sr ${OUTDIR}/rootfs/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/libm.so

sudo cp ${TOOLCHAIN_PATH}/libc/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
sudo ln -sr ${OUTDIR}/rootfs/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/libresolv.so

sudo cp ${TOOLCHAIN_PATH}/libc/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/
sudo ln -sr ${OUTDIR}/rootfs/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/libc.so

# We are not sure we need this one.
sudo cp ${TOOLCHAIN_PATH}/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
sudo ln -sr ${OUTDIR}/rootfs/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/ld-linux-aarch64.so

# TODO: Make device nodes
mkdir -p ${OUTDIR}/rootfs/dev

sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
echo "Finder app path"
echo ${FINDER_APP_DIR}
CROSS_COMPILE=${CROSS_COMPILE} make clean
CROSS_COMPILE=${CROSS_COMPILE} make all
cp ./writer ${OUTDIR}/rootfs/home/

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
# f. Copy your finder.sh, conf/username.txt, 
# conf/assignment.txt and finder-test.sh scripts 
# from Assignment 2 into the outdir/rootfs/home directory.

cp ./finder.sh ${OUTDIR}/rootfs/home/
cp ./finder-test.sh ${OUTDIR}/rootfs/home/
cp -r ./conf/ ${OUTDIR}/rootfs/home
cp ./autorun-qemu.sh ${OUTDIR}/rootfs/home/


# TODO: Chown the root directory
sudo chown root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs/
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

echo "File ${OUTDIR}/initramfs.cpio.gz created."