#!/bin/bash
red='\033[0;31m'
plain='\033[0m'
#内网ip地址获取
#ip=$(ifconfig | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}' | awk 'NR==1')
ip=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^127\.|^255\.|^0\." | head -n 1)
if [[ ! -n "$ip" ]]; then
    ip="你的路由器IP"
fi
#外网IP地址获取
if [ "$address" = "" ];then
address=$(curl -sS --connect-timeout 10 -m 60 http://members.3322.org/dyndns/getip)
fi

#默认安装目录/root
name=/root
#默认安装端口
nport=9999
clear
# check root
[[ $EUID -ne 0 ]] && echo -e "\033[31m错误: 必须使用root用户运行此脚本！\033[0m" && exit 1

echo -e "输入portainer汉化文件安装目录:\n"
read -p "输入目录名,留空默认:${red} $name ${plain}: " webdir
    if [[ ! -n "$webdir" ]]; then
        webdir=$name
    fi
read -p "输入服务端口（请避开已使用的端口）留空默认${red}[$nport]${plain}: " port
    if [[ ! -n "$port" ]]; then
        port=$nport
    fi
if [[ ! -d "$webdir" ]] ; then
mkdir -p $webdir
cd $webdir
else
cd $webdir
fi
curl -sL https://raw.githubusercontent.com/jellyfina/portainer-ce/main/public.tar.gz | tar xz

rm -rf public

mv public-public public
    
docker stop portainer

docker rm portainer

docker rmi portainer/portainer

docker rmi portainer/portainer-ce

read -p "是否重置portainer账户密码(首次安装直接输入 y )[y/n]" user
case $user in
    y) docker volume rm portainer_data;;
n) echo "不重置，你将使用之前安装的portainer账户密码";;
*) echo "你输入的不是 y/n"
exit;;
esac
echo "现在开始安装Portainer"



docker run -d --restart=always --name="portainer" -p $port:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v $webdir/public:/public jellyfina/portainer-ce


if [ "docker inspect --format '{{.State.Running}}' portainer" != "true" ]
then {
echo -e "=================================================================="
echo -e "portainer部署成功，使用外网访问管理地址时请先做好 \033[31m端口映射\033[0m"
echo -e "=================================================================="
echo -e "\033[31m外网管理地址:\033[0m http://$address:$port "
echo -e "\033[31m内网管理地址:\033[0m http://$ip:$port "
echo -e "=================================================================="
}
else
{
    echo "抱歉，portainer安装失败，请尝试多运行几次脚本或者检查网络是否正常"
}
fi
