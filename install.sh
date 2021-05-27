#!/bin/bash
# -*- coding: utf-8 -*-
# @Software     : PyCharm
# @Author       : gxggxl
# @File         : install.sh
# @Time         : 2021/3/10 21:00
# @Project Name : ServerStatus-sh

#获取路径
#path=$(cd "$(dirname "$0")" || exit pwd)

me=0

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

#检查账户权限
function check_root() {
  if [ $UID -ne 0 ] ; then
    echo -e "当前用户是 ROOT 用户，可以继续操作" && sleep 1
  else
    echo -e "当前非 ROOT 账号(或没有 ROOT 权限)，无法继续操作，请更换 ROOT 账号或使用 su命令获取临时 ROOT 权限" && exit 1
  fi
}

#检查系统
check_sys() {
  release=$(uname -a)
  strX="当前的操作系统是"
  if [[ $release =~ "Darwin" ]]; then
    echo "$strX MacOS"
    release="macos"
  elif [[ $release =~ "centos" ]]; then
    echo "$strX centos"
    release="centos"
  elif [[ $release =~ "ubuntu" ]]; then
    echo "$strX ubuntu"
    release="ubuntu"
  else
    echo "$release"
  fi
}

# 检查 gcc 依赖
check_gcc_installed_status() {
  if [ -z "$(command -v gcc)" ]; then
    echo -e "gcc 依赖没有安装，开始安装..."
    check_root
    if [[ ${release} == "centos" ]]; then
      yum update && yum install gcc -y
    elif [[ ${release} == "macos" ]]; then
      brew install gcc
    else
      apt-get update && apt-get install gcc -y
    fi
    if [ -z "$(command -v gcc)" ]; then
      echo -e "gcc 依赖安装失败，请检查！" && exit 1
    else
      echo -e "gcc 依赖安装成功！"
    fi
  fi
}

# 检查 python-pip 依赖
check_python_pip_installed_status() {
  if [ -z "$(command -v pip)" ]; then
    echo -e "python-pip 依赖没有安装，开始安装..."
    if [[ ${release} == "centos" ]]; then
      yum install python-pip -y
    elif [[ ${release} == "macos" ]]; then
      brew install python-pip
    else
      apt-get install python-pip -y
    fi
    if [ -z "$(command -v pip)" ]; then
      echo -e "python-pip 依赖安装失败，请检查！" && exit 1
    else
      echo -e "python-pip 依赖安装成功！"
    fi
  fi
}

# 检查 python psutil 模块
check_python_psutil_installed_status() {
  if pip list | grep -o 'psutil'; then
    echo -e "python psutil 模块没有安装，开始安装..."
    pip install psutil
    if pip list | grep -o 'psutil'; then
      echo -e "python psutil 依赖安装失败，请检查！" && exit 1
    else
      echo -e "python psutil 依赖安装成功！"
    fi
  fi
}

# 安装服务端环境
install_server_u() {
  green "安装服务端环境..."
  yum -y install epel-release
  yum -y install python-devel
  check_gcc_installed_status
  check_python_pip_installed_status
  check_python_psutil_installed_status
  green "环境安装成功"
}

# 安装客户端环境
install_client_u() {
  green "安装客户端环境..."
  check_gcc_installed_status
  yum -y install epel-release
  yum -y install python-devel
  check_python_pip_installed_status
  check_python_psutil_installed_status
  green "环境安装成功"
}

# 安装服务端
install_server() {
  install_server_u
  #  git clone https://github.com/gxggxl/ServerStatus-sh.git ServerStatus
  git clone https://gitee.com/gxggxl/ServerStatus-sh.git ServerStatus
  cp -rf /root/ServerStatus/web/* /www/wwwroot/info.gxusb.com
  cd ServerStatus/server || exit
  make
  #  ./sergate &
  # 运行服务端
  green "请按Ctrl+C继续"
  /root/ServerStatus/server/sergate --config=/root/ServerStatus/server/config.json --web-dir=/www/wwwroot/info.gxusb.com

  green "将ServerStatus服务端，添加到crontab任务列表..."
  cat <<EOF >>/etc/crontab
#ServerStatus-server Start
@reboot root /root/ServerStatus/server/sergate --config=/root/ServerStatus/server/config.json --web-dir=/www/wwwroot/info.gxusb.com
#ServerStatus-server End
EOF
  green "@reboot root /root/ServerStatus/server/sergate --config=/root/ServerStatus/server/config.json --web-dir=/www/wwwroot/info.gxusb.com \n已添加到/etc/crontab"
  green "服务端安装成功"

  yellow "安装服务端时，默认安装客户端"
  printf "默认安装:y/n:"
  read -e -r cccc
  if [[ $cccc == "y" ]] || [[ $cccc == "" ]]; then
    install_client
  else
    exit
  fi
  exit
}

# 安装客户端
install_client() {
  #  install_client_u
  if ls ./*ServerStatus*; then
    echo "mkdir ServerStatus"
    mkdir ServerStatus
  else
    echo "目录已存在"
  fi
  cd ServerStatus || exit
  if ls ./*clients*; then
    echo "mkdir clients"
    mkdir clients
  else
    echo "目录已存在"
  fi
  cd ../

  wget -O "/root/ServerStatus/clients/client-linux.py" "https://raw.githubusercontent.com/gxggxl/ServerStatus-sh/master/clients/client-linux.py"
  chmod 700 /root/ServerStatus/clients/client-linux.py
  read -e -r -p "请输入服务端IP地址:" server
  read -e -r -p "请输入用户名:" user
  # 后台运行
  green "请手动运行客户端"
  echo "nohup python3 /root/ServerStatus/clients/client-linux.py SERVER=$server USER=$user >/root/client-linux.txt 2>&1 &"

  yellow "将客户端设置跟随系统启动"
  cat <<EOF >>/etc/crontab
#ServerStatus-client Start
@reboot root python3 /root/ServerStatus/clients/client-linux.py SERVER=$server USER=$user
#ServerStatus-client End
EOF
  green "@reboot root python3 /root/ServerStatus/clients/client-linux.py SERVER=$server USER=$user \n已添加到/etc/crontab"
}

# 卸载服务端
uninstall_server() {
  grep /etc/crontab | sed '/^#ServerStatus-server/,/^#ServerStatus-server End/d' >tmp && mv tmp /etc/crontab
  red "正在删除服务端网站文件..."
  rm -rfv /www/wwwroot/info.gxusb.com
  green "网站文件已删除"
  red "正在删除服务端文件..."
  rm -rfv /root/ServerStatus
  green "服务端文件已删除"
}

# 卸载客户端
uninstall_client() {
  grep /etc/crontab | sed '/^#ServerStatus-client/,/^#ServerStatus-client End/d' >tmp && mv tmp /etc/crontab
  red "正在删除客户端文件..."
  rm -rfv /root/ServerStatus/clients
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

  if ((me == 1)); then
    red "输入无效，请输入对应选项的数字："
  else
    echo "请输入对应选项的数字："
  fi

  read -r numa

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
    me=1
    menu
    ;;
  esac
}

check_sys
menu
