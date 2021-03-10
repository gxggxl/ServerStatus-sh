#!/bin/bash

# 功能性函数：
# 定义几个颜色
purple() { #基佬紫
  echo -e "\\033[35;1m${*}\\033[0m"
}
tyblue() { #天依蓝
  echo -e "\\033[36;1m${*}\\033[0m"
}
green() { #原谅绿
  echo -e "\\033[32;1m${*}\\033[0m"
}
yellow() { #鸭屎黄
  echo -e "\\033[33;1m${*}\\033[0m"
}
red() { #姨妈红
  echo -e "\\033[31;1m${*}\\033[0m"
}
blue() { #蓝色
  echo -e "\\033[34;1m${*}\\033[0m"
}

#red $(command -v python)

#检查账户权限
check_root() {
    if [ 0 == $UID ]; then
        echo -e "当前用户是 ROOT 用户，可以继续操作" && sleep 1
    else
        echo -e "当前非 ROOT 账号(或没有 ROOT 权限)，无法继续操作，请更换 ROOT 账号或使用 su命令获取临时 ROOT 权限" && exit 1
    fi
}

# 安装环境
install_u() {
  green "安装环境..."
  yum -y install epel-release
  yum -y install python-pip
  yum -y install gcc
  yum -y install python-devel
  green "环境安装成功"
}

#获取路径
#path=$(cd "$(dirname "$0")" || exit pwd)

# 安装服务端
install_server() {
#  install_u
#  git clone https://github.com/gxggxl/ServerStatus-sh.git ServerStatus
  git clone https://gitee.com/gxggxl/ServerStatus-sh.git ServerStatus
  cp -rf root/ServerStatus/web/* /www/wwwroot/info.gxusb.com
  cd ServerStatus/server || exit
  make
  ./sergate

  #运行服务端
  ./sergate --config=config.json --web-dir=/www/wwwroot/info.gxusb.com

  # shellcheck disable=SC2242
  path=$(cd "$(dirname "$0")" || exit pwd)
  green "将ServerStatus服务端，添加到crontab任务列表..."
  cat <<EOF >>/etc/crontab
#ServerStatus-server Start
@reboot root $path/sergate --config=$path/config.json --web-dir=/www/wwwroot/info.gxusb.com
#ServerStatus-server End
EOF

  green "服务端安装成功"
  yellow "安装服务端时，默认安装客户端"
  printf "默认安装:y/n:"
  read -e cccc
  if [[ $cccc == "y" ]] || [[ $cccc == "" ]]; then
    install_client
    else
      exit
  fi
  exit
}

# 安装客户端
install_client() {
  wget -P /root/ServerStatus https://raw.githubusercontent.com/gxggxl/ServerStatus-sh/master/clients/client-linux.py
  chmod 755 /root/ServerStatus/client-linux.py
  # shellcheck disable=SC2162
  read -e -p "请输入服务端IP地址:" server
  # shellcheck disable=SC2162
  read -e -p "请输入用户名:" user
  cat <<EOF >>/etc/crontab
#ServerStatus-client Start
@reboot root /root/ServerStatus/client-linux.py SERVER=$server USER=$user
#ServerStatus-client End
EOF
/root/ServerStatus/client-linux.py SERVER=$server USER=$user
}

# 卸载服务端
uninstall_server() {
  cp /etc/crontab crontab.backup
  sed '/^#ServerStatus-server/,/^#ServerStatus-server End/d' crontab.backup >/etc/crontab
  red "正在删除服务端网站文件..."
  rm -rfv /home/wwwroot/default/*
  green "网站文件已删除"
}

# 卸载客户端
uninstall_client() {
  cp /etc/crontab crontab.backup
  sed '/^#ServerStatus-client/,/^#ServerStatus-client End/d' crontab.backup >/etc/crontab
  red "正在删除客户端文件..."
  rm -rfv /root/ServerStatus
  green "客户端文件已删除"
}

function menu() {
  #  clear
  cat <<EOF
---------------------------------------------
|**********   $(green "ServerStatus-sh")   ************|
| https://github.com/gxggxl/ServerStatus-sh |
---------------------------------------------
$(tyblue " 1)安装服务端")
$(tyblue " 2)安装客户端")
$(red " 3)卸载服户端")
$(red " 4)卸载客户端")
$(yellow " 5)退出")
EOF
  # shellcheck disable=SC2162
  read -p "请输入对应选项的数字：" numa
  case $numa in
  1)
    echo "安装服务端!"
    install_server
    ;;
  2)
    echo "安装客户务端!"
    install_client
    ;;
  3)
    echo "卸载服务端"
    uninstall_server
    ;;
  4)
    yellow "卸载客户端"
    uninstall_client
    ;;
  5)
    clear
    exit
    ;;
  *)
    red "输入无效，请重新输入选项"
    menu
    ;;
  esac
}

menu