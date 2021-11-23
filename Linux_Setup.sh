#!/bin/sh


# 字体颜色配置
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[OK]${Font}"
ERROR="${Red}[ERROR]${Font}"
cron_update_file="/usr/bin/cron_update.sh"
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
    INS="${INS}"
    #wget -N -P /etc/yum.repos.d/ https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/basic/nginx.repo
  elif [[ "${ID}" == "ol" ]]; then
    print_ok "当前系统为 Oracle Linux ${VERSION_ID} ${VERSION}"
    INS="${INS}"
	print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
    #wget -N -P /etc/yum.repos.d/ https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/basic/nginx.repo
  elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 9 ]]; then
    print_ok "当前系统为 Debian ${VERSION_ID} ${VERSION}"
    INS="apt install -y"
    # 清除可能的遗留问题
    #rm -f /etc/apt/sources.list.d/nginx.list
    #$INS lsb-release gnupg2

    #echo "deb http://nginx.org/packages/debian $(lsb_release -cs) nginx" >/etc/apt/sources.list.d/nginx.list
    #curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -

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

  $INS dbus

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
function sshd() {
    sed -i 's/^.\? *PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^.\? *Port.*$/Port 26254/g' /etc/ssh/sshd_config
    sed -i 's/^.\?ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
    systemctl restart sshd
    judge "sshd_config 修改"
}
function firewall() {
  if [[ "${ID}" == "centos" ]]; then
    systemctl stop firewalld
    systemctl disable firewalld
	${INS} iptables iptables-services
	IPTABLEF=/etc/sysconfig/iptables
  elif [[ "${ID}" == "debian" ]]; then
    systemctl stop ufw
    systemctl disable ufw
	${INS} iptables
	IPTABLEF=/etc/iptables/rules.v4
  fi    
  judge "iptables 安装"
  cat <<EOF>${IPTABLEF}
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -s 127.0.0.1/32 -d 127.0.0.1/32 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 26254 -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
# Completed on Wed Jun 16 04:51:40 2021
EOF
  if [[ "${ID}" == "centos" ]]; then
    systemctl restart iptables
    systemctl enable iptables
  else
    iptables-restore <${IPTABLEF}
	cat <<EOF>/etc/network/if-pre-up.d/iptables
#!/bin/sh
/sbin/iptables-restore </etc/network/if-pre-up.d/iptables
EOF
  chmod +x /etc/network/if-pre-up.d/iptables
  fi
  iptables -L    
}
function installTools() {
  timedatectl set-timezone Asia/Shanghai
  if [[ "${ID}" == "centos" ]]; then
    ${INS} epel-release https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    judge "epel-release 与 remi 源安装"
	${INS} vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools
    judge "vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools 安装"
  elif [[ "${ID}" == "debian" ]]; then
	${INS} vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools gnupg2 ca-certificates lsb-release
    judge "vim net-tools lrzsz zip unzip tar wget vim lrzsz lsof curl net-tools gnupg2 ca-certificates lsb-release 安装"
  fi
}
function php_remove() {
  if [[ "${ID}" == "centos" ]]; then
    systemctl stop php-fpm
    yum remove -y php-*
    
    if [[ $(rpm -qa|grep -c php) -lt 1 ]]; then
     judge "php 卸载完毕"
    else     
     rpm -qa|grep php
     judge "php 没有卸载完全"
    fi
  elif [[ "${ID}" == "debian" ]]; then
    apt purge -y $(dpkg -l | grep php| awk '{print $2}' |tr "\n" " ")
  fi
}
function php() {
  if  command -v php; then
    read -rp "php已经安装是否重装(y/n)：" answer
      if echo "$answer" | grep -iq "^y" ;then
	    php_remove
	  else
	    return 
	  fi
  fi
  if [[ "${ID}" == "centos" ]]; then
	  
    yum module -y reset php
    yum module list php
    read -rp "请输入PHP 版本:" PHPV    
    yum module -y enable php:$PHPV
    ${INS} php
    judge "php 安装"
    ${INS} php-mbstring php-pecl-apcu php-opcache php-json php-mysqlnd \
php-zip php-process php-bcmath php-gmp php-intl php-gd
    judge "php 其他模块 安装"
  elif [[ "${ID}" == "debian" ]]; then
    ${INS} lsb-release apt-transport-https ca-certificates 
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php.list
	apt update
	read -rp "请输入PHP 版本:" PHPV
	${INS} php${PHPV}
	judge "php${PHPV} 安装"
	${INS} php${PHPV}-{dom,xml,curl,fpm,apcu,opcache,json,gmp,bcmath,bz2,intl,gd,mbstring,mysql,zip}
  fi
}

function php_fpm() {


  if [[ "${ID}" == "centos" ]]; then
   php_fpmcfg=/etc/php-fpm.d/www.conf
   php_inicfg=/etc/php.ini
  elif [[ "${ID}" == "debian" ]]; then
    PHPV=$(/usr/bin/php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
    php_fpmcfg=/etc/php/${PHPV}/fpm/pool.d/www.conf
    php_inicfg=/etc/php/${PHPV}/fpm/php.ini
  fi
    sed -i 's/^.\?env\[HOSTNAME\]/env\[HOSTNAME\]/g' $php_fpmcfg
    sed -i 's/^.\?env\[PATH\]/env\[PATH\]/g' $php_fpmcfg
    Para_Modify $php_fpmcfg 'user' 'nginx'
    Para_Modify $php_fpmcfg 'group' 'nginx'
    Para_Modify $php_fpmcfg 'listen' '127.0.0.1:9000'
    Para_Modify $php_fpmcfg 'listen.group' 'nginx'
    Para_Modify $php_fpmcfg 'listen.owner' 'nginx'
    cat $php_fpmcfg |grep -v ^#|grep -v ^\;|grep -v ^$
	chown nginx:nginx /var/lib/php/sessions
    chown nginx:nginx /var/lib/php/session
    chown root:nginx /var/lib/php/wsdlcache
    chown root:nginx /var/lib/php/opcache
	
    Para_Modify $php_inicfg 'memory_limit' '512M'
  if [[ "${ID}" == "centos" ]]; then
    systemctl restart php-fpm
    systemctl enable php-fpm
    systemctl status php-fpm
  elif [[ "${ID}" == "debian" ]]; then
    systemctl restart php${PHPV}-fpm
    systemctl enable php${PHPV}-fpm
    systemctl status php${PHPV}-fpm
  fi  

}
function BBR() {

    sed -i '/^.*net.core.default_qdisc.*$/d' /etc/sysctl.conf
    sed -i '/^.*net.ipv4.tcp_congestion_control.*$/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p
}
function acme_install() {
  rm  -rf .acme.sh
  read -rp "CF_Key:" CF_Keyin
  curl -L get.acme.sh | bash
  judge "安装 acme"
  source .bashrc 
  echo "SAVED_CF_Key='${CF_Keyin}'">>/root/.acme.sh/account.conf 
  echo "SAVED_CF_Email='zhangguoping8935@163.com'">>/root/.acme.sh/account.conf 
  .acme.sh/acme.sh --register-account -m zhangguoping8935@gmail.com
}

function acme_url() {
  read -rp "root domain:" ROOTD
  .acme.sh/acme.sh --issue --dns dns_cf -d "${ROOTD}" -d "*.${ROOTD}"
  .acme.sh/acme.sh --install-cert -d "${ROOTD}" --fullchain-file /etc/ssl/cert.pem --key-file /etc/ssl/privkey.key
  cat <<EOF> "${cron_update_file}" 
#!/usr/bin/env bash
domain = ${ROOTD}
systemctl stop nginx &> /dev/null
sleep 1
"/root/.acme.sh"/acme.sh --issue --dns dns_cf  -d "\${domain}" -d "*.\${domain}" &> /dev/null
"/root/.acme.sh"/acme.sh --install-cert -d "${domain}" --fullchain-file /etc/ssl/cert.pem --key-file /etc/ssl/privkey.key &> /dev/null
sleep 1
systemctl start nginx &> /dev/null
EOF
  if [[ "${ID}" == "centos" || "${ID}" == "ol" ]]; then
    ${INS} crontabs
  else
    ${INS} cron
  fi
  judge "安装 crontab"
  if [[ "${ID}" == "centos" || "${ID}" == "ol" ]]; then
    CRONF=/var/spool/cron/root
	CRONCMD=crond
  else
    CRONF=/var/spool/cron/crontabs/root
	CRONCMD=cron
  fi
  sed -i "/acme.sh/d" ${CRONF}
  sed -i "/^.*${cron_update_file}.*$/d" ${CRONF}
  echo "0 3 1 * * bash ${cron_update_file}">>${CRONF}
  judge "cron 计划任务更新"
  systemctl restart ${CRONCMD} && systemctl enable ${CRONCMD} 
  
}
function nginx_install() {
  if [[ "${ID}" == "centos" || "${ID}" == "ol" ]]; then
    yum module -y  reset nginx
    yum module list nginx
    read -rp "请输入nginx 版本:" NGINXV    
    yum module -y enable nginx:$NGINXV   

  else
    $INS curl gnupg2 ca-certificates lsb-release
	echo "deb https://nginx.org/packages/debian/ $(lsb_release -cs) nginx" >/etc/apt/sources.list.d/nginx.list
	curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
	apt update
    systemctl stop apache2
    systemctl disable apache2
  fi

  ${INS} nginx
  judge "nginx 安装"
  systemctl enable nginx
  systemctl restart nginx
  systemctl status nginx
}

function v2ray_install() {
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    judge "v2ray 安装"
}
function nc_install() {
    read -rp "请输入NextCloud 链接:" NEXTCLOUDURL
    wget $NEXTCLOUDURL
    unzip nextcloud*.zip
    mv nextcloud  /var/www/
    rm -f nextcloud*.zip
    chown -R nginx:nginx /var/www/nextcloud    
    judge "NextCloud 安装到/var/www/nextcloud"
}
function mysql_install() {
    ${INS} mysql mysql-server
    judge "mysql 安装"
    systemctl restart mysqld && systemctl enable  mysqld
}
function git_install() {
    ${INS} git
    useradd git
    sed -i 's/\/home\/git:.*$/\/home\/git:\/usr\/bin\/git-shell/g' /etc/passwd
}
function nginx_config() {
	wget $githuburl/nginx.zip
	mkdir -p ziptmp
	rm -f ziptmp/*
	unzip -d ziptmp  nginx.zip
	rm -f nginx.zip
	read -n1 -p  "是否安装nginx.conf[y/n]?"  answer
    if echo "$answer" | grep -iq "^y" ;then
	   cat ziptmp/nginx.conf >/etc/nginx/nginx.conf
	   judge "nginx.conf 替换"
	fi
	read -n1 -p  "是否安装nextcloud.conf[y/n]?"  answer
    if echo "$answer" | grep -iq "^y" ;then
	   cat ziptmp/nextcloud.conf >/etc/nginx/conf.d/nextcloud.conf
	   read -p  "请输入域名:"  domm
	   sed -i "s/server_name.*/server_name $domm;/g" /etc/nginx/conf.d/nextcloud.conf
	   judge "nextcloud.conf 替换"
	fi
	read -n1 -p  "是否安装80.conf[y/n]?"  answer
    if echo "$answer" | grep -iq "^y" ;then
	   cat ziptmp/80.conf >/etc/nginx/conf.d/80.conf
	   judge "80conf 替换"
	fi
	read -n1 -p  "是否安装worpress配置文件[y/n]?"  answer
    if echo "$answer" | grep -iq "^y" ;then
	   read -p  "请输入域名:"  domm
	   cat ziptmp/*.xyz.conf >/etc/nginx/conf.d/$domm.conf
	   sed -i "s/server_name.*/server_name $domm;/g" /etc/nginx/conf.d/$domm.conf
	   judge "$domm.conf 替换"
	fi
    ls -alh /etc/nginx/conf.d/
    systemctl restart nginx
    systemctl status nginx
		
}
function file_down() {

  echo -e "${Green}$githuburl${Font}"
  echo -e "${Green}1.${Font} Centos8_Setup.sh"
  echo -e "${Green}2.${Font} nginx.zip"
  echo -e "${Green}3.${Font} besttrace" 
  read -rp "请输入：" choose_num
  case $choose_num in
  1)  
    wget $githuburl/Centos8_Setup.sh
  ;;
  2)  
    wget $githuburl/nginx.zip
  ;;
  3)  
    wget $githuburl/besttrace
	chmod +x besttrace
  ;;
  *)
    wget $githuburl/$choose_num
    ;;
  esac

}
menu() {
  is_root
  system_check
  echo -e "\t---authored by zhang---"

  echo -e "${Green}1.${Font} 常用工具包安装"
  echo -e "${Green}2.${Font} ssd_config 配置"
  echo -e "${Green}3.${Font} 关闭FireWall安装iptables并配置规则"  

  
  echo -e "${Green}4.${Font} php 安装"
  echo -e "${Green}5.${Font} php-fpm 修改配置"
  
  echo -e "${Green}6.${Font} BBR开启"
  
  echo -e "${Green}7.${Font} acme 安装"
  echo -e "${Green}8.${Font} acme 域名"  
  
  echo -e "${Green}9.${Font} NGINX安装"  
  echo -e "${Green}10.${Font} NextCloud安装"
  echo -e "${Green}11.${Font} V2fly安装"
  
  echo -e "${Green}12.${Font} mysql安装"
  
  echo -e "${Green}13.${Font} git安装"
  
  echo -e "${Green}14.${Font} Nginx配置文件下载"
  
  echo -e "${Green}~~~~~~~~~~~组合命令~~~~~~~~~~~${Font}"
  echo -e "${Green}21.${Font} 执行1-3所有步骤"
  echo -e "${Green}22.${Font} 执行4和5 php安装配置"
  echo -e "${Green}23.${Font} acme 整个配置"
  echo -e "${Green}24.${Font} acme升级"
  echo -e "${Green}25.${Font} 文件下载"
  echo -e "${Green}26.${Font} bench.sh  VPS性能测试"
  echo -e "${Green}27.${Font} 流媒体解锁测试"
  echo -e "${Green}28.${Font} 一键DD"
  
  echo -e "${Green}~~~~~~~~~~~卸载相关~~~~~~~~~~~${Font}"
  echo -e "${Green}31.${Font} php卸载"
  echo -e "${Green}40.${Font} 退出"
  read -rp "请输入数字：" menu_num
  case $menu_num in
  1)
    installTools    
    ;;
  2)
    sshd
    ;;
  3)
    firewall
    ;;
  4)
    php
    ;;
  5)
    php_fpm
    ;;
  6)
    BBR
    ;;
  7)
    acme_install
    ;;
  8)
    acme_url
    ;;
  9)
    nginx_install
    ;;
  10)
    nc_install
    ;;
  11)
    v2ray_install
    ;;
  12)
    mysql_install
    ;;
  13)
    git_install
    ;;
  14)
    nginx_config
    ;;
  21)
    installTools
    sshd
    firewall
    ;;
  22)
    php
    php_fpm
    ;;
  23)
    acme_install
    acme_url
    ;;
  24)
    "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh"
    ;;
  25)
    file_down
    ;;
  26)
    echo "wget -qO- bench.sh| bash"
    wget -qO- bench.sh | bash
    ;;
  27)
    wget $githuburl/checkNF.sh
	bash checkNF.sh
    ;;
  28)
    wget $githuburl/InstallNET.sh
	bash checkNF.sh
    ;;
  31)
    php_remove
    ;;
  40)
    exit 0
    ;;
  13)
    DOMAIN=$(cat ${domain_tmp_dir}/domain)
    nginx_conf="/etc/nginx/conf.d/${DOMAIN}.conf"
    modify_port
    restart_all
    ;;

  22)
    tail -f $xray_error_log
    ;;
  23)
    if [[ -f $xray_conf_dir/config.json ]]; then
      basic_ws_information
    else
      print_error "xray 配置文件不存在"
    fi
    ;;
  *)
    print_error "请输入正确的数字 $menu_num"
    ;;
  esac
}
menu "$@"
