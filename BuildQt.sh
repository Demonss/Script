#!/bin/sh

Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[OK]${Font}"
ERROR="${Red}[ERROR]${Font}"

QT551ROOT=${PWD}
QT551ARM_QMAKE=${QT551ROOT}/qtbase/mkspecs/linux-arm-gnueabi-g++/qmake.conf


function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 完成"
    sleep 1
  else
    print_error "$1 失败"
    exit 1
  fi
}
function system_check() {
  source '/etc/os-release'
  if [[ "${ID}" == "centos" ]]; then
    INS="yum install -y"
  elif [[ "${ID}" == "debian" ]]; then
    INS="apt install -y"
  elif [[ "${ID}" == "ubuntu" ]]; then
    INS="apt install -y"
  else
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
  fi
}
function installDep() {
  ${INS} python3 python-is-python3 lsb-core lib32stdc++6  g++  
}
function qt551Autoconfig() {
  FILENAME=${QT551ROOT}/autoconfigQt551.sh
cat <<EOF>${FILENAME}
./configure -prefix ${QT551ROOT}/arm-qt -v \\
-opensource \\
-confirm-license \\
-release \\
-strip \\
-shared \\
-xplatform linux-arm-gnueabi-g++ \\
-optimized-qmake \\
-no-rpath \\
-pch \\
-skip qt3d \\
-skip qtactiveqt \\
-skip qtandroidextras \\
-skip qtcanvas3d \\
-skip qtconnectivity \\
-skip qtdoc \\
-skip qtlocation \\
-skip qtmacextras \\
-skip qtscript \\
-skip qtsensors \\
-skip qtsvg \\
-skip qttools \\
-skip qttranslations \\
-skip qtwayland \\
-skip qtwebengine \\
-skip qtwinextras \\
-skip qtx11extras \\
-skip qtxmlpatterns \\
-make libs \\
-nomake tools -nomake tests -nomake examples \\
-gui \\
-widgets \\
-no-dbus \\
-no-opengl \\
-linuxfb \\
-no-iconv \\
-no-glib \\
-qt-pcre \\
-qt-zlib \\
-no-openssl \\
-qt-freetype \\
-qt-harfbuzz \\
-no-xcb \\
-qt-libpng \\
-qt-libjpeg \\
-qt-sql-sqlite \\
-no-tslib \\
2>&1 |tee logAutoconfig\$( date '+%m%d%H%M' ).log
EOF
  chmod +x ${FILENAME}
  read -rp  "是否支持tslib[y/n]?" answer
  if echo "$answer" | grep -iq "^y" ;then
    read -rp  "输入tslib根目录:" tslibroot
    sed -i "s|-no-tslib|-tslib -I${tslibroot}/include -L${tslibroot}/lib|g" ${FILENAME}
    judge "${FILENAME} 添加tslib支持"
  fi
}
function mkspec() {
  FILENAME=${QT551ROOT}/qtbase/mkspecs/linux-arm-gnueabi-g++/qmake.conf  
  read -rp "请输入交叉编译器bin目录[/opt/zlg_arm_linux/bin]:" NXPTOOLCHAIN
  if [ -z "$NXPTOOLCHAIN" ] ; then
    NXPTOOLCHAIN=/opt/zlg_arm_linux/bin
  fi
cat <<EOF>${FILENAME}
#
# qmake configuration for building with arm-linux-gnueabi-g++
#
MAKEFILE_GENERATOR = UNIX
CONFIG += incremental
QMAKE_INCREMENTAL_STYLE = sublib
QT_QPA_DEFAULT_PLATFORM = linuxfb
QMAKE_CFLAGS += -O2 -march=armv7-a -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard
QMAKE_CXXFLAGS += -O2 -march=armv7-a -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard
include(../common/linux.conf)
include(../common/gcc-base-unix.conf)
include(../common/g++-unix.conf)
# modifications to g++.conf
QMAKE_CC = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-gcc
QMAKE_CXX = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-g++
QMAKE_LINK = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-g++
QMAKE_LINK_SHLIB = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-g++
# modifications to linux.conf
QMAKE_AR = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-ar cqs
QMAKE_OBJCOPY = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-objcopy
QMAKE_NM = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-nm -P
QMAKE_STRIP = ${NXPTOOLCHAIN}/arm-linux-gnueabihf-strip
load(qt_config)
EOF
}
function mkqt() {
  make -j $(nproc --all) 2>&1 |tee logMake$( date '+%m%d%H%M' ).log
}
function patchqt() {
  FBDIR=${QT551ROOT}/qtbase/src/plugins/platforms/linuxfb
  read -rp  "输入打包文件路径:" FILENAME
  patch -p1 -d ${FBDIR} <${FILENAME}
}
menu() {
  system_check
  if [ $# -gt 0 ]; then
    menu_num=$1
  else
    echo -e "\t---authored by zhang---"
    echo -e "${Green}1.${Font} 安装Qt5.5.1 autoconfig脚本"
    echo -e "${Green}2.${Font} 安装Qt编译依赖项"
    echo -e "${Green}3.${Font} 添加mkspec"
    echo -e "${Green}4.${Font} make"
    echo -e "${Green}5.${Font} FB支持旋转打包"
    read -rp "请输入数字：" menu_num
  fi
  case $menu_num in
  1)
    qt551Autoconfig
    ;;
  2)
    installDep
    ;;
  3)
    mkspec
    ;;
  4)
    mkqt
    ;;
  5)
    patchqt
    ;;
  *)
    qt551Autoconfig
    ;;
  esac
}
menu "$@"
