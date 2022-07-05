export SDKTARGETSYSROOT=/opt/fsl-imx-x11/qt5.6.1/sysroots/cortexa7hf-neon-poky-linux-gnueabi
export OECORE_TARGET_SYSROOT="$SDKTARGETSYSROOT"
export OECORE_NATIVE_SYSROOT="/opt/fsl-imx-x11/qt5.6.1/sysroots/x86_64-pokysdk-linux"
export PATH=$OECORE_NATIVE_SYSROOT/usr/bin:$OECORE_NATIVE_SYSROOT/usr/sbin:$OECORE_NATIVE_SYSROOT/bin:$OECORE_NATIVE_SYSROOT/sbin:$OECORE_NATIVE_SYSROOT/usr/bin/../x86_64-pokysdk-linux/bin:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-gnueabi:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-uclibc:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-musl:$PATH
export CCACHE_PATH=$OECORE_NATIVE_SYSROOT/usr/bin:$OECORE_NATIVE_SYSROOT/usr/bin/../x86_64-pokysdk-linux/bin:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-gnueabi:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-uclibc:$OECORE_NATIVE_SYSROOT/usr/bin/arm-poky-linux-musl:$CCACHE_PATH
export PKG_CONFIG_SYSROOT_DIR=$SDKTARGETSYSROOT
export PKG_CONFIG_PATH=$SDKTARGETSYSROOT/usr/lib/pkgconfig
export CONFIG_SITE=/opt/fsl-imx-x11/qt5.6.1/site-config-cortexa7hf-neon-poky-linux-gnueabi

export OECORE_ACLOCAL_OPTS="-I /opt/fsl-imx-x11/qt5.6.1/sysroots/x86_64-pokysdk-linux/usr/share/aclocal"
unset command_not_found_handle
export CC="arm-poky-linux-gnueabi-gcc  -march=armv7ve -mfpu=neon  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=$SDKTARGETSYSROOT"
export CXX="arm-poky-linux-gnueabi-g++  -march=armv7ve -mfpu=neon  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=$SDKTARGETSYSROOT"
export CPP="arm-poky-linux-gnueabi-gcc -E  -march=armv7ve -mfpu=neon  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=$SDKTARGETSYSROOT"
export AS="arm-poky-linux-gnueabi-as "
export LD="arm-poky-linux-gnueabi-ld  --sysroot=$SDKTARGETSYSROOT"
export GDB=arm-poky-linux-gnueabi-gdb
export STRIP=arm-poky-linux-gnueabi-strip
export RANLIB=arm-poky-linux-gnueabi-ranlib
export OBJCOPY=arm-poky-linux-gnueabi-objcopy
export OBJDUMP=arm-poky-linux-gnueabi-objdump
export AR=arm-poky-linux-gnueabi-ar
export NM=arm-poky-linux-gnueabi-nm
export M4=m4
export TARGET_PREFIX=arm-poky-linux-gnueabi-
export CONFIGURE_FLAGS="--target=arm-poky-linux-gnueabi --host=arm-poky-linux-gnueabi --build=x86_64-linux --with-libtool-sysroot=$SDKTARGETSYSROOT"
export LDFLAGS="-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed"
export CPPFLAGS=""
export KCFLAGS="--sysroot=$SDKTARGETSYSROOT"
export OECORE_DISTRO_VERSION="4.1.15-2.1.0"
export OECORE_SDK_VERSION="4.1.15-2.1.0"
export ARCH=arm
export CROSS_COMPILE=arm-poky-linux-gnueabi-

export THE_QT_ROOT_BIN="/opt/fsl-imx-x11/qt5.6.1/sysroots/x86_64-pokysdk-linux/usr/bin/qt5"
export PATH=$THE_QT_ROOT_BIN:$PATH
export OE_QMAKE_CFLAGS="$CFLAGS"
export OE_QMAKE_CXXFLAGS="$CXXFLAGS"
export OE_QMAKE_LDFLAGS="$LDFLAGS"
export OE_QMAKE_CC=$CC
export OE_QMAKE_CXX=$CXX
export OE_QMAKE_LINK=$CXX
export OE_QMAKE_AR=$AR
export QT_CONF_PATH=$THE_QT_ROOT_BIN/qt.conf
export OE_QMAKE_LIBDIR_QT=`qmake -query QT_INSTALL_LIBS`
export OE_QMAKE_INCDIR_QT=`qmake -query QT_INSTALL_HEADERS`
export OE_QMAKE_MOC=$THE_QT_ROOT_BIN/moc
export OE_QMAKE_UIC=$THE_QT_ROOT_BIN/uic
export OE_QMAKE_RCC=$THE_QT_ROOT_BIN/rcc
export OE_QMAKE_QDBUSCPP2XML=$THE_QT_ROOT_BIN/qdbuscpp2xml
export OE_QMAKE_QDBUSXML2CPP=$THE_QT_ROOT_BIN/qdbusxml2cpp
export OE_QMAKE_QT_CONFIG=`qmake -query QT_INSTALL_LIBS`/qt5/mkspecs/qconfig.pri
export OE_QMAKE_PATH_HOST_BINS=$THE_QT_ROOT_BIN
export QMAKESPEC=`qmake -query QT_INSTALL_LIBS`/qt5/mkspecs/linux-oe-g++
export OE_QMAKE_STRIP=$STRIP

