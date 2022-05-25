#!/bin/sh
# 字体颜色配置
#bash <(curl -L https://github.com/Demonss/Script/raw/main/Linux_Setup.sh)
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[OK]${Font}"
ERROR="${Red}[ERROR]${Font}"

githuburl=https://github.com/Demonss/Script/raw/main

function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 完成"
    sleep 1
  else
    print_error "$1 失败"
    exit 1
  fi
}
function is_root() {
  if [[ 0 == "$UID" ]]; then
    print_ok "当前用户是 root 用户，开始安装流程"
  else
    print_error "当前用户不是 root 用户，请切换到 root 用户后重新执行脚本"
    exit 1
  fi
}
function system_check() {
  source '/etc/os-release'
  if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
    print_ok "当前系统为 Centos ${VERSION_ID} ${VERSION}"
    INS="yum install -y"
    #wget -N -P /etc/yum.repos.d/ https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/basic/nginx.repo
  elif [[ "${ID}" == "ol" ]]; then
    print_ok "当前系统为 Oracle Linux ${VERSION_ID} ${VERSION}"
    INS="yum install -y"
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
    #wget -N -P /etc/yum.repos.d/ https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/basic/nginx.repo
  elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 9 ]]; then
    print_ok "当前系统为 Debian ${VERSION_ID} ${VERSION}"
    INS="apt install -y"
    #apt update
  elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 18 ]]; then
    print_ok "当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME}"
    INS="apt install -y"
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
  else
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
  fi
  if [[ $(grep "nogroup" /etc/group) ]]; then
    cert_group="nogroup"
  fi

  #$INS dbus
  # 关闭各类防火墙
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl stop nftables
  systemctl disable nftables
  systemctl stop ufw
  systemctl disable ufw
}
#属性=修改
Para_Modify() {
  sed -i "s/^.\? *$2 *=.*$/$2 = $3/g" $1
  judge "$1 modify $2 to $3"
}
function permitroot() {
  sed -i 's/^.\? *PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
  sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  sed -i 's/^.\?ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
  sed -i 's/.*quiet_success.*/#permit root/g' /etc/pam.d/gdm-password
  sed -i '9 i\ AllowRoot=true\n AutomaticLoginEnable=True\n' /etc/gdm3/custom.conf
  systemctl restart sshd
  judge "允许root登录修改"
}

function apt_config() {
  judge "apt修改设置代理"
  read -rp  "请输入代理地址IP:port"  answer
  cat <<EOF>/etc/apt/apt.conf.d/proxy.conf
  Acquire::http::proxy "socks5h://${answer}";
EOF

  cat <<EOF>/etc/apt/sources.list
  deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
  deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
  deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
  deb-src http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
  deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
  deb-src http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
  deb http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse 
  deb-src http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse 
  deb http://archive.canonical.com/ubuntu focal partner 
  deb-src http://archive.canonical.com/ubuntu focal partner
EOF
}
function installTools() {
  timedatectl set-timezone Asia/Shanghai
  ${INS} vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools gnupg2 ca-certificates lsb-release openssh-server open-vm-tools-desktop open-vm-tools build-essential
  judge "vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools gnupg2 ca-certificates lsb-release 安装"
  sed -i "s/mouse=a/mouse-=a/g" /usr/share/vim/vim*/defaults.vim
  touch ~/.vimrc
}

function samba_install() {
  ${INS} samba 
  mkdir /samba 
  chmod 777 /samba 
  systemctl enable smbd
  cat <<EOF>>/etc/samba/smb.conf
  [VM share] 
  comment = Users profiles 
  path = /samba 
  guest ok = yes 
  writable = yes 
  public =yes 
  create mask = 0666 
  directory  mask = 0777
EOF
  systemctl start smbd

}

function Snap_rm() {
  apt autoremove --purge snapd
}


menu() {
  export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
  if [ $# -gt 0 ]; then
    menu_num=$1
  else
    is_root
    system_check
    echo -e "\t---authored by zhang---"
    echo -e "${Green}1.${Font} 常用工具包安装"
    echo -e "${Green}2.${Font} ssh,登录 允许root"
    echo -e "${Green}3.${Font} apt 配置"

    echo -e "${Green}4.${Font} samba开启"


    read -rp "请输入数字：" menu_num
  fi
  case $menu_num in
  1)
    installTools
    ;;
  2)
    permitroot
    ;;
  3)
    apt_config
    ;;
  4)
    samba_install
    ;;

  41)
    module_remove
    ;;
  40)
    exit 0
    ;;
  *)
    print_error "请输入正确的数字 $menu_num"
    ;;
  esac
}
menu "$@"
