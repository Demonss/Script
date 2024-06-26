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
cron_update_file="/usr/bin/cron_update.sh"
mysql_autoupdate_sh="/usr/bin/mysqlbackup.sh"
mysql_startifstop_sh="/usr/bin/myifstoprun.sh"
WordPressRoot="/var/www/wordpress"
githuburl=https://github.com/Demonss/Script/raw/main

function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
function rand(){
    min=$1
    max=$(($2 - $min + 1))
    num=$(($RANDOM+1000000000)) # 增加一个10位的数再求余
    echo $(($num%$max + $min))
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
function sshd() {
  sed -i 's/^.\? *PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
  sed -i 's/^.\? *Port.*$/Port 26254/g' /etc/ssh/sshd_config
  sed -i 's/^.\?ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
  sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  read -rp "是否为ssh配置Key登录?(y/n):" answer
  if echo "$answer" | grep -iq "^y" ;then
    wget $githuburl/res/io_test.rar
    mkdir -p ~/.ssh
    cat io_test.rar >~/.ssh/authorized_keys
    rm io_test.rar
    read -rp "已经配置了key登陆是否禁用密码登陆?(y/n):" answer
    if echo "$answer" | grep -iq "^y" ;then
      sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
    fi
#    sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
#  else
#    sed -i 's/^.\? *PasswordAuthentication.*$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  fi
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
    mkdir /etc/iptables
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
/sbin/iptables-restore <${IPTABLEF}
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
    sed -i "s/mouse=a/mouse-=a/g" /usr/share/vim/vim*/defaults.vim
  fi
  touch ~/.vimrc
}
function php_remove() {
  if [[ "${ID}" == "centos" ]]; then
    systemctl stop php-fpm
    PGPMODULES=$(rpm -qa|grep php|tr "\n"  " ")
    yum remove -y ${PGPMODULES}
    judge "${PGPMODULES} 卸载"
  elif [[ "${ID}" == "debian" ]]; then
    apt purge -y $(dpkg -l | grep php| awk '{print $2}' |tr "\n" " ")
  fi
}
function module_remove() {
  echo -e "${Green}1.${Font} 卸载 php"
  echo -e "${Green}2.${Font} 卸载 nginx"
  echo -e "${Green}3.${Font} 卸载 mysql"
  echo -e "${Green}4.${Font} 卸载 mariaDB"
  read -rp "请输入模块序号或者名字：" module_num
  case $module_num in
  1)
    MODEL_NAMEC="php"
    MODEL_NAMED="php"
    ;;
  2)
    MODEL_NAMEC="nginx"
    MODEL_NAMED="nginx"
    ;;
  3)
    MODEL_NAMEC="^mysql"
    MODEL_NAMED=" mysql"
    ;;
  4)
    MODEL_NAMEC="^mariadb"
    MODEL_NAMED=" mariadb"
    ;;
  *)
    print_error "请输入正确的数字"
    ;;
  esac
  if [[ "${ID}" == "centos" ]]; then
    yum autoremove -y $(rpm -qa |grep "$MODEL_NAMEC"|tr "\n" " ")
  elif [[ "${ID}" == "debian" ]]; then
    apt purge -y $(dpkg -l |grep "$MODEL_NAMED"|awk '{ print $2 }'|tr "\n" " ")
  fi
}
function php() {
  if [[ "${ID}" == "centos" ]]; then
    PHPINS=$(rpm -qa|grep -c php)
  elif [[ "${ID}" == "debian" ]]; then
    PHPINS=$(dpkg -l|grep -c php)
  fi
  if [ $PHPINS -ge 1 ]; then
    read -rp "php已经安装是否重装(y/n)：" answer
      if echo "$answer" | grep -iq "^y" ;then
        module_remove "php"
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
    ${INS} php-{mbstring,pecl-apcu,opcache,json,mysqlnd,zip,process,bcmath,gmp,intl,gd}
    judge "php 其他模块 安装"
    systemctl stop httpd
    systemctl disable httpd
  elif [[ "${ID}" == "debian" ]]; then
    read -rp "请输入PHP 版本:" PHPV
    NUMPHP=$(apt search "^php${PHPV}-" 2>/dev/null|grep -c php)
    if [[ $NUMPHP -le 10 ]]; then
      ${INS} lsb-release apt-transport-https ca-certificates
      wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
      echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php.list
      apt update -y
    fi
    NUMPHP=$(apt search "^php${PHPV}-" 2>/dev/null|grep -c php)
    if [[ $NUMPHP -le 10 ]]; then
       print_error "无法找到php${PHPV}"
       exit 1
    fi
    ${INS} php${PHPV} php${PHPV}-fpm
    judge "php${PHPV} 安装"
    ${INS} php${PHPV}-{dom,xml,curl,apcu,opcache,json,gmp,bcmath,bz2,intl,gd,mbstring,mysql,zip}
    judge "php${PHPV} 其他模块安装"
    systemctl stop apache2
    systemctl disable apache2
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
  if [[ -e /etc/nginx/conf.d/php-fpm.conf ]]; then
    rm -f /etc/nginx/conf.d/php-fpm.conf
  fi
}
function BBR() {
    sed -i '/^.*net.core.default_qdisc.*$/d' /etc/sysctl.conf
    sed -i '/^.*net.ipv4.tcp_congestion_control.*$/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.tun0.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
}
function acme_install() {
  rm  -rf .acme.sh
  curl -L get.acme.sh | bash
  judge "安装 acme"
  source .bashrc
  wget wget $githuburl/res/myacme.zip
  unzip  myacme.zip
  rm -f myacme.zip
  if [ -e myacme.conf ]; then
    CF_API=$(grep ^SAVED_CF_Key myacme.conf |tr "\n" " ")
    echo ${CF_API}>>/root/.acme.sh/account.conf
    CF_EMAIL=$(grep ^SAVED_CF_Email myacme.conf |tr "\n" " ")
    echo ${CF_EMAIL}>>/root/.acme.sh/account.conf
    ACME_E=$(grep acme_Email myacme.conf |awk -F= '{print $2}'|tr "\n" " ")
    .acme.sh/acme.sh --register-account -m $ACME_E
    rm myacme.conf
  fi
}

function acme_url() {
  echo -e "${Green}1.${Font} 切换 Let’s Encrypt"
  echo -e "${Green}2.${Font} 切换 Buypass"
  echo -e "${Green}3.${Font} 切换 ZeroSSL"
  echo -e "${Green}4.${Font} 切换 SSL.com"
  echo -e "${Green}5.${Font} 切换 Google Public CA"
  read -rp "请输入：" choose_num
  case $choose_num in
  1)
    CA_SERVER="letsencrypt"
    ;;
  2)
    CA_SERVER="buypass"
    ;;
  3)
    CA_SERVER="zerossl"
    ;;
  4)
    CA_SERVER="ssl.com"
    ;;
  5)
    CA_SERVER="google"
    ;;
  esac
  if [ $CA_SERVER ]; then
    "/root/.acme.sh"/acme.sh --set-default-ca --server $CA_SERVER
  fi
  read -rp "your domain:" ROOTD
  .acme.sh/acme.sh --issue --force --dns dns_cf -d "${ROOTD}" -d "*.${ROOTD}"
  .acme.sh/acme.sh --install-cert -d "${ROOTD}" --fullchain-file /etc/ssl/${ROOTD}.pem --key-file /etc/ssl/${ROOTD}.key
  #Domain更新脚本
  if [[ -f ${cron_update_file}  ]]; then
    print_error  "${cron_update_file}  exist   请手动追加以下内容到 ${cron_update_file}:"
    echo "/root/.acme.sh"/acme.sh --issue --dns dns_cf  -d ${ROOTD} -d *.${ROOTD} 
    echo "/root/.acme.sh"/acme.sh --install-cert -d "${ROOTD}" --fullchain-file /etc/ssl/${ROOTD}.pem --key-file /etc/ssl/${ROOTD}.key
    return
  fi
  cat <<EOF> "${cron_update_file}"
#!/usr/bin/env bash
systemctl stop nginx &> /dev/null
sleep 1
"/root/.acme.sh"/acme.sh --issue --dns dns_cf  -d ${ROOTD} -d *.${ROOTD} &> /var/log/${ROOTD}.acme.log
"/root/.acme.sh"/acme.sh --install-cert -d "${ROOTD}" --fullchain-file /etc/ssl/${ROOTD}.pem --key-file /etc/ssl/${ROOTD}.key &> /var/log/${ROOTD}.acme.log
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
    CRONSERVER=crond
  else
    CRONF=/var/spool/cron/crontabs/root
    CRONSERVER=cron
  fi
  sed -i "/acme.sh/d" ${CRONF}
  sed -i "/^.*${cron_update_file}.*$/d" ${CRONF}
  echo "0 3 1 * * bash ${cron_update_file}">>${CRONF}
  judge "cron 计划任务更新"
  systemctl restart ${CRONSERVER} && systemctl enable ${CRONSERVER}
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
  if [[ -e /etc/nginx/conf.d/php-fpm.conf ]]; then
    rm -f /etc/nginx/conf.d/php-fpm.conf
  fi
  if [[ -e /etc/nginx/conf.d/default.conf ]]; then
    rm -f /etc/nginx/conf.d/default.conf
  fi
  systemctl enable nginx
  systemctl restart nginx
  systemctl status nginx
}

function v2ray_install() {
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
  judge "v2ray 安装"
}
function nc_install() {
  echo "https://nextcloud.com/install/#instructions-server"
  read -rp "请输入NextCloud 链接:" NEXTCLOUDURL
  wget $NEXTCLOUDURL
  nczip=$(basename "$NEXTCLOUDURL")
  echo $nczip
  unzip $nczip
  rm -f $nczip
  mkdir -p /var/www/
  mv nextcloud  /var/www/
  
  if [[ -d /var/lib/php/sessions ]]; then
    chown nginx:nginx /var/lib/php/sessions
  fi
  if [[ -d /var/lib/php/session ]]; then
    chown nginx:nginx /var/lib/php/session
  fi
  if [[ -d /var/lib/php/wsdlcache ]]; then
    chown root:nginx /var/lib/php/wsdlcache
  fi
  if [[ -d /var/lib/php/opcache ]]; then
    chown root:nginx /var/lib/php/opcache
  fi
  chown -R nginx:nginx /var/www/nextcloud
  rm -rf /var/www/nextcloud/core/skeleton/*
  sed -i '/^);/e cat ziptmp\/NextCloudConfig' /var/www/nextcloud/config/config.php
  judge "NextCloud 安装到/var/www/nextcloud"
}
function wp_installupdate() {
  wpurl=https://wordpress.org/latest.tar.gz
  wget $wpurl
  wpzip=$(basename "$wpurl")
  tar -xzvf $wpzip
  rm -f $wpzip
  chown -R nginx:nginx wordpress
  if [[ -d /var/www/wordpress ]]; then
    echo "/var/www/wordpress 存在升级.................."
    rm -rf /var/www/wordpress/wp-admin /var/www/wordpress/wp-includes
    mv wordpress/wp-admin /var/www/wordpress
    mv wordpress/wp-includes /var/www/wordpress
    mv -f wordpress/*.php /var/www/wordpress
    rm -rf wordpress
  else
    mkdir -p /var/www
    echo "/var/www/wordpress 不存在 进行安装.................."
    mv wordpress /var/www/
  fi
  ls -alh /var/www/wordpress
  judge "Wordpress 升级/安装"
}
function mysql_install() {
  ${INS} mysql mysql-server
  judge "mysql 安装"
  systemctl restart mysqld && systemctl enable  mysqld
}
function mariadb_install() {
  if [[ "${ID}" == "debian" ]]; then
    ${INS} mariadb-server mariadb-client
    judge "mariadb-server mariadb-client 安装"
  else
    print_error "mariadb 仅仅支持debian"
    return
  fi
  systemctl restart mariadb && systemctl enable  mariadb
}
function wp_modifiedLogin() {  
  read -rp "请输入现在的登录php名字(wp-login):" WPLOGINCUR
  if [ -z "$WPLOGINCUR" ] ; then
    WPLOGINCUR="wp-login.php"
  fi
  if [[ $WPLOGINCUR != *php ]]; then
    WPLOGINCUR=${WPLOGINCUR}.php
  fi
  cd $WordPressRoot
  if [ ! -f "${WPLOGINCUR}" ]; then
    print_error "${WordPressRoot}/${WPLOGINCUR} 不存在！！！"
    return
  fi
  echo "old login php name: ${WPLOGINCUR}"
  read -rp "请输入新的登录php名字:" WPLOGINNEW
  if [[ $WPLOGINNEW != *php ]]; then
    WPLOGINNEW=${WPLOGINNEW}.php
  fi
  echo "New login php name: ${WPLOGINNEW}"
  cp -a wp-includes/general-template.php wp-includes/general-templatebak.php
  sed -i s/${WPLOGINCUR}/${WPLOGINNEW}/g wp-includes/general-template.php
  mv ${WPLOGINCUR} ${WPLOGINNEW}
  sed -i s/${WPLOGINCUR}/${WPLOGINNEW}/g ${WPLOGINNEW}
  systemctl restart nginx php7.4-fpm
  judge "new login php ${WPLOGINNEW}"
  echo "if you use fail2ban please replace /etc/fail2ban/filter.d/wordpress.conf"
}
function mariadb_conf() {
  echo -e "${Green}1.${Font} 修改root密码"
  echo -e "${Green}2.${Font} 增加一个数据库"
  echo -e "${Green}3.${Font} 数据库备份"
  echo -e "${Green}4.${Font} 数据库恢复"
  echo -e "${Green}5.${Font} 删除一个数据库"
  echo -e "${Green}6.${Font} 数据库定时备份"
  read -rp "请输入：" choose_num
  case $choose_num in
  1)
    read -rp "请输入新密码：" PASSWDROOT
    mysql -uroot -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${PASSWDROOT}'"
    echo "export PASSWDROOT=${PASSWDROOT}">/etc/profile.d/mysqladdpd.sh
    ;;
  2)
    if [ -z "$PASSWDROOT" ]; then
      print_error "请先export PASSWDROOT="
      exit 1
    fi
    read -rp "请依次输入：数据库名称 用户名 用户密码:" dbname username userpass
    if [ -z "$dbname" ] || [ -z "$username" ] || [ -z "$userpass" ] ; then
      print_error "请输入正确：数据库名称 用户名 用户密码"
      exit 1
    fi
    mkdir -p /etc/mysqlpasswd
    echo "DB_NAME=$dbname">>/etc/mysqlpasswd/$dbname
    echo "DB_USER=$username">>/etc/mysqlpasswd/$dbname
    echo "DB_PASSWORD=$userpass">>/etc/mysqlpasswd/$dbname
    mysql -uroot -p${PASSWDROOT} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    echo "Creating new user..."
    mysql -uroot -p${PASSWDROOT} -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
    mysql -uroot -p${PASSWDROOT} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
    mysql -uroot -p${PASSWDROOT} -e "FLUSH PRIVILEGES;"
    mysql -uroot -p${PASSWDROOT} -e "show databases;"
    echo "Finished"
    ;;
  3)
    if [ -z "$PASSWDROOT" ]; then
      print_error "请先export PASSWDROOT="
      exit 1
    fi
    mysql -uroot -p${PASSWDROOT} -e "show databases;"
    read -rp "请输入备份数据库名称：" dbname
    dumpdate=$(date '+%Y%m%d-%H%M%S')
    mysqldump -uroot -p${PASSWDROOT} -e "${dbname}">~/${dbname}_${dumpdate}.sql
    ls -alh ~
    ;;
  4)
    if [ -z "$PASSWDROOT" ]; then
      print_error "请先export PASSWDROOT="
      exit 1
    fi
    mysql -uroot -p${PASSWDROOT} -e "show databases;"
    ls ~
    #sqlname=$(ls ~ |grep ".sql"|tr '\n' ' ')
    read -rp "请输入 恢复数据库名称 Sql文件：" dbname sqlname
    mysql -uroot -p${PASSWDROOT} $dbname <~/$sqlname
    mysql -uroot -p${PASSWDROOT} -e "show tables from $dbname;"
    ;;
   5)
    if [ -z "$PASSWDROOT" ]; then
      print_error "请先export PASSWDROOT="
      exit 1
    fi
    mysql -uroot -p${PASSWDROOT} -e "show databases;"
    read -rp "请输入恢复数据库名称：" dbname
    mysqladmin drop $dbname -f -uroot -p${PASSWDROOT}
    ;;
    6)
    if [ -z "$PASSWDROOT" ]; then
      print_error "请先export PASSWDROOT="
      exit 1
    fi
    if [[ "${ID}" == "centos" || "${ID}" == "ol" ]]; then
      CRONF=/var/spool/cron/root
      CRONSERVER=crond
      CRONCMD=crontab
    else
      CRONF=/var/spool/cron/crontabs/root
      CRONSERVER=cron
      CRONCMD=crontab
    fi
    mysql -uroot -p${PASSWDROOT} -e "show databases;"
    read -rp "请输入定时备份数据库名称：" dbname
    cat <<"EOF"> "${mysql_autoupdate_sh}"
#!/bin/bash
#保存备份个数，备份31天数据
number=15
#备份保存路径
backup_dir=/root/mysql_backup
#日期
dd=`date +%Y-%m-%d-%H-%M-%S`
dumpdate=$(date '+%Y%m%d-%H%M%S')
#备份工具
tool=mysqldump
#用户名
username=root
#密码
password=$1
#将要备份的数据库
database_name=$2

if  [  $#  -lt 2 ];then
  echo "too few params"
  exit 1
fi

#如果文件夹不存在则创建
if [ ! -d $backup_dir ]; 
then     
  mkdir -p $backup_dir; 
fi

#简单写法  mysqldump -u root -p123456 users > /root/mysqlbackup/users-$filename.sql
$tool -u $username -p${password} -e "${database_name}" > $backup_dir/${database_name}_${dumpdate}.sql

    
#mysqldump -uroot -p${PASSWDROOT} -e "${database_name}">~/${database_name}_${dumpdate}.sql

#写创建备份日志
echo "create $backup_dir/$database_name-$dd.dupm" >> $backup_dir/log.txt

#找出需要删除的备份
delfile=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | head -1`

#判断现在的备份数量是否大于$number
count=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | wc -l`

if [ $count -gt $number ]
then
  #删除最早生成的备份，只保留number数量的备份
  rm $delfile
  #写删除文件日志
  echo "delete $delfile" >> $backup_dir/log.txt
fi
EOF
    echo "$(rand 0 59) $(rand 0 3) * * $(rand 1 6) ${mysql_autoupdate_sh} ${PASSWDROOT} ${dbname}">>${CRONF}
    chmod +x ${mysql_autoupdate_sh}
    ${CRONCMD} -l
    print_ok "已经创建备份任务，默认是一星期一次"
    ;;
  *)
    print_error "请输入正确的数字"
    ;;
  esac

  systemctl restart mariadb
}
function git_install() {
  ${INS} git
  read -rp  "请输入git用户名:"  gituser
  useradd $gituser
  mkdir -p /home/$gituser
  mkdir -p /home/$gituser/.ssh
  chown -R $gituser:$gituser /home/$gituser
  sed -i 's/\/home\/"$gituser":.*$/\/home\/"$gituser":\/usr\/bin\/git-shell/g' /etc/passwd
}
function fail2banInstall() {
  ${INS} fail2ban
  read -rp "请输入wp登录php(wp-login)：" loginphp
  if [ -z "$loginphp" ] ; then
    loginphp=wp-login
  fi
  if [[ $loginphp != *php ]]; then
    loginphp=${loginphp}.php
  fi
  cat <<"EOF"> /etc/fail2ban/jail.d/wordpress.conf
[wordpress]
enabled = true
filter = wordpress
action = iptables-allports[name=all,blocktype=DROP]
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 120
bantime = 3600
usedns = no
EOF
  cat <<"EOF"> /etc/fail2ban/filter.d/wordpress.conf
[Definition]
failregex = ^<HOST> .* "(GET|POST) /+${loginphp}
            ^<HOST> .* "(GET|POST).*" (404|444|403|400) .*$
EOF
  systemctl restart fail2ban
  systemctl enable fail2ban
  systemctl status fail2ban
}
function nginx_config() {
  wget $githuburl/res/nginx.zip
  mkdir -p ziptmp
  rm -f ziptmp/*
  unzip -d ziptmp  nginx.zip
  rm -f nginx.zip
  rm /etc/nginx/conf.d/*.conf
  read -rp  "是否安装nginx.conf[y/n]?"  answer
  if echo "$answer" | grep -iq "^y" ;then
    cat ziptmp/nginx.conf >/etc/nginx/nginx.conf
    mv ziptmp/ipblock.conf /etc/nginx/conf.d/
    mkdir -p /etc/ssl
    mv ziptmp/fake.* /etc/ssl/
    judge "nginx.conf 配置文件安装"
  fi
  read -rp  "是否安装nextcloud.conf[y/n]?"  answer
  if echo "$answer" | grep -iq "^y" ;then
    cat ziptmp/nextcloud.conf >/etc/nginx/conf.d/nextcloud.conf
    read -p  "请输入域名:"  domm
    rootdomm=$(echo $domm|awk -F . '{ print $(NF-1)"."$NF }')
    sed -i "s/server_name .*/server_name $domm;/g" /etc/nginx/conf.d/nextcloud.conf
    sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/ssl\/${rootdomm}.pem;/g" /etc/nginx/conf.d/nextcloud.conf
    sed -i "s/ssl_certificate_key.*/ssl_certificate_key \/etc\/ssl\/${rootdomm}.key;/g" /etc/nginx/conf.d/nextcloud.conf
    judge "nextcloud.conf 配置文件安装"
  fi
  read -rp  "是否安装worpress配置文件[y/n]?"  answer
  if echo "$answer" | grep -iq "^y" ;then
    read -rp  "请输入域名:"  domm
    rootdomm=$(echo $domm|awk -F . '{ print $(NF-1)"."$NF }')
    cat ziptmp/wordpress.conf >/etc/nginx/conf.d/${domm}.conf
    sed -i "s/server_name .*/server_name $domm;/g" /etc/nginx/conf.d/${domm}.conf
    sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/ssl\/${rootdomm}.pem;/g" /etc/nginx/conf.d/${domm}.conf
    sed -i "s/ssl_certificate_key.*/ssl_certificate_key \/etc\/ssl\/${rootdomm}.key;/g" /etc/nginx/conf.d/${domm}.conf
    judge "$domm.conf 配置文件安装"
  fi
  cat ziptmp/FastCGI.conf >/etc/nginx/conf.d/FastCGI.conf  
  ls -alh /etc/nginx/conf.d/
  systemctl restart nginx
  systemctl status nginx
}

function wp_addifstoprun() {

  if [[ "${ID}" == "centos" || "${ID}" == "ol" ]]; then
    CRONF=/var/spool/cron/root
    CRONSERVER=crond
  else
    CRONF=/var/spool/cron/crontabs/root
    CRONSERVER=cron
  fi
  cat <<"EOF"> "${mysql_startifstop_sh}"
#!/bin/bash
service=$1

/bin/systemctl -q is-active "$service.service"
status=$?
if [ "$status" == 0 ]; then
   echo "$service is running!!!"
else
   /bin/systemctl start "$service.service"
fi
EOF
  chmod +x ${mysql_startifstop_sh}
  read -rp "请输入尝试启动服务：" serverN
  echo "$(rand 0 59) $(rand 0 3) * * * ${mysql_startifstop_sh} ${serverN}">>${CRONF}
  systemctl restart ${CRONSERVER} && systemctl enable ${CRONSERVER}
}
function file_down() {
  echo -e "${Green}$githuburl${Font}"
  echo -e "${Green}1.${Font} Centos8_Setup.sh"
  echo -e "${Green}2.${Font} nginx.zip"
  echo -e "${Green}3.${Font} besttrace"
  echo -e "${Green}4.${Font} wp-fastest-cache-premium"
  echo -e "${Green}5.${Font} IOTest.sh"
  read -rp "请输入：" choose_num
  case $choose_num in
  1)
    wget $githuburl/Centos8_Setup.sh
    ;;
  2)
    wget $githuburl/res/nginx.zip
    ;;
  3)
    rm -f besttrace
    wget $githuburl/res/besttrace
    chmod +x besttrace
    ;;
  4)
    rm -f wp-fastest-cache-premium_1.6.2.zip
    wget $githuburl/res/wp-fastest-cache-premium_1.6.2.zip
    ;;
  5)
    rm -f IOTest.sh
    wget $githuburl/res/IOTest.sh
    ;;
  *)
    wget $githuburl/$choose_num
    ;;
  esac

}
function io_test() {
  dddd=$(date)
  ffff=$((LANG=C dd if=/dev/zero of=/root/benchtest bs=64k count=4k conv=fdatasync && rm -f /root/benchtest ) 2>&1 | awk -F, 'END { print $NF }')
  echo $dddd $ffff >>/root/io_test
}
function fastest_cache_premium() {

  if [[ -d /var/www/wordpress ]]; then
    rm -r wp-fastest-cache-premium*.zip
    wget $githuburl/res/wp-fastest-cache-premium_1.6.2.zip
    unzip wp-fastest-cache-premium_1.6.2.zip
    rm -rf  /var/www/wordpress/wp-content/plugins/wp-fastest-cache-premium
    mv wp-fastest-cache-premium  /var/www/wordpress/wp-content/plugins    
    judge "wp-fastest-cache-premium 安装"
  else
    print_error "WordPress 未安装!!!!!!!!!!!!"
    exit 1
  fi

}
menu() {
  export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
  is_root
  system_check
  if [ $# -gt 0 ]; then
    menu_num=$1
  else
    echo -e "\t---authored by zhang---"
    echo -e "${Green}1.${Font} 常用工具包安装"
    echo -e "${Green}2.${Font} ssd_config 配置"
    echo -e "${Green}3.${Font} 关闭FireWall安装iptables并配置规则"

    echo -e "${Green}4.${Font} BBR开启"

    echo -e "${Green}5.${Font} NGINX安装"

    echo -e "${Green}6.${Font} php 安装"
    echo -e "${Green}7.${Font} php  fpm 修改配置"

    echo -e "${Green}8.${Font} acme 安装"
    echo -e "${Green}9.${Font} acme 域名"

    echo -e "${Green}10.${Font} NextCloud安装"
    echo -e "${Green}11.${Font} V2fly安装"
    echo -e "${Green}12.${Font} mysql安装"
    echo -e "${Green}13.${Font} git安装增加用户"
    echo -e "${Green}14.${Font} Nginx配置文件下载"
    echo -e "${Green}15.${Font} MariaDB安装"
    echo -e "${Green}16.${Font} Wordpress安装/升级"
    echo -e "${Green}17.${Font} 为服务增加停止后启动"
    echo -e "${Green}18.${Font} Wordpress修改登录php"
    echo -e "${Green}19.${Font} Fail2ban安装保护WP"

    echo -e "${Green}~~~~~~~~~~~组合命令~~~~~~~~~~~${Font}"
    echo -e "${Green}21.${Font} 执行1-3所有步骤"
    echo -e "${Green}22.${Font} 执行php安装与配置"
    echo -e "${Green}23.${Font} acme 整个配置"
    echo -e "${Green}24.${Font} acme 升级"
    echo -e "${Green}25.${Font} github文件下载"
    echo -e "${Green}26.${Font} bench.sh  VPS性能测试"
    echo -e "${Green}27.${Font} 流媒体解锁测试"
    echo -e "${Green}28.${Font} 一键DD"
    echo -e "${Green}29.${Font} MariaDB configure"
    echo -e "${Green}30.${Font} wp-fastest-cache-premium"
    echo -e "${Green}31.${Font} IO 测试"

    echo -e "${Green}~~~~~~~~~~~卸载相关~~~~~~~~~~~${Font}"
    echo -e "${Green}41.${Font} 模块卸载"
    echo -e "${Green}40.${Font} 退出"
    read -rp "请输入数字：" menu_num
  fi
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
    BBR
    ;;
  5)
    nginx_install
    ;;
  6)
    php
    ;;
  7)
    php_fpm
    ;;
  8)
    acme_install
    ;;
  9)
    acme_url
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
  15)
    mariadb_install
    ;;
  16)
    wp_installupdate
    ;;
  17)
    wp_addifstoprun
    ;;
  18)
    wp_modifiedLogin
    ;;
  19)
    fail2banInstall
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
  29)
    mariadb_conf
    ;;
  30)    
    fastest_cache_premium
    ;;
  31)    
    io_test
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
