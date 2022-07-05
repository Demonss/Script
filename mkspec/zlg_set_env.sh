export PATH=/opt/zlg_arm_linux/bin:$PATH
export CC=arm-linux-gnueabihf-gcc
export CXX=arm-linux-gnueabihf-g++
export GDB=arm-linux-gnueabihf-gdb
export STRIP=arm-linux-gnueabihf-strip
export RANLIB=arm-linux-gnueabihf-ranlib
export OBJCOPY=arm-linux-gnueabihf-objcopy
export OBJDUMP=arm-linux-gnueabihf-objdump
export AR=arm-linux-gnueabihf-ar
export NM=arm-linux-gnueabihf-nm

export CFLAGS="-O2 -march=armv7-a -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard"
export CXXFLAGS="-O2 -march=armv7-a -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard"
export LDFLAGS="-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed"
#
export THE_QT_ROOT="/opt/qt5.5.1"
export THE_QT_ROOT_BIN=$THE_QT_ROOT/bin
export PATH=$THE_QT_ROOT_BIN:$PATH
export OE_QMAKE_CFLAGS="$CFLAGS"
export OE_QMAKE_CXXFLAGS="$CXXFLAGS"
export OE_QMAKE_LDFLAGS="$LDFLAGS"
export OE_QMAKE_CC=$CC
export OE_QMAKE_CXX=$CXX
export OE_QMAKE_LINK=$CXX
export OE_QMAKE_AR=$AR
export OE_QMAKE_STRIP=$STRIP
export QT_CONF_PATH=$THE_QT_ROOT_BIN/qt.conf
export OE_QMAKE_LIBDIR_QT=`qmake -query QT_INSTALL_LIBS`
export OE_QMAKE_INCDIR_QT=`qmake -query QT_INSTALL_HEADERS`
export OE_QMAKE_MOC=$THE_QT_ROOT_BIN/moc
export OE_QMAKE_UIC=$THE_QT_ROOT_BIN/uic
export OE_QMAKE_RCC=$THE_QT_ROOT_BIN/rcc
export OE_QMAKE_QDBUSCPP2XML=$THE_QT_ROOT_BIN/qdbuscpp2xml
export OE_QMAKE_QDBUSXML2CPP=$THE_QT_ROOT_BIN/qdbusxml2cpp
export OE_QMAKE_QT_CONFIG=$THE_QT_ROOT/mkspecs/qconfig.pri
export OE_QMAKE_PATH_HOST_BINS=$THE_QT_ROOT_BIN
#export QMAKESPEC=`qmake -query QT_INSTALL_LIBS`/qt5/mkspecs/linux-oe-g++


