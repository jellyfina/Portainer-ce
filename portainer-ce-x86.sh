#!/bin/bash
red='\033[0;31m'
plain='\033[0m'
#内网ip地址获取
#ip=$(ifconfig | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}' | awk 'NR==1')
ip=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^127\.|^255\.|^0\." | head -n 1)
if [[ ! -n "$ip" ]]; then
    ip="你的内网IP"
fi
#外网IP地址获取
if [ "$address" = "" ];then
address=$(curl https://ip.3322.net)
fi

clear
#检查并安装Docker
	echo '-------------------------------------------'
	docker_path=$(which docker)
	if [ -e "${docker_path}" ]
	then
		echo 'Docker已安装，继续执行'
	else
		read -p "Docker未安装，是否安装Docker?(y/n):" is_docker
		if [ $is_docker == 'y' ]
			then
				curl -fsSL https://get.docker.com -o get-docker.sh
				sh get-docker.sh
			else
				echo '放弃安装！'
				echo '-------------------------------------------'
				exit
		fi
	fi
	#启动docker
	systemctl enable docker
	systemctl start docker
	echo '-------------------------------------------'
# check root
[[ $EUID -ne 0 ]] && echo -e "\033[31m错误: 必须使用root用户运行此脚本！\033[0m" && exit 1
cd /root
curl -sL https://raw.650070.xyz/jellyfina/portainer-ce/main/public.tar.gz | tar xz
echo -e "\033[32m==================================================================\033[0m"
echo -e "\033[33m首次部署portainer时如出现\033[0m \033[31mError\033[0m \033[33m错误提示属正常现象，无需理会\033[0m"
rm -rf public

mv public-public public
    
docker stop portainer

docker rm portainer

docker rmi $(docker images | grep portai | tr -s ' ' | cut -d ' ' -f 3)

echo -e "\033[32m==================================================================\033[0m"
echo -e "\033[33m首次重置portainer账户密码时出现\033[0m \033[31mError\033[0m \033[33m错误提示属正常现象，无需理会\033[0m"
read -p "是否重置portainer账户密码(首次安装直接输入 y )[y/n]" user
case $user in
    y) docker volume rm portainer_data;;
n) echo "不重置，你将使用之前安装的portainer账户密码";;
*) echo "你输入的不是 y/n，已退出安装"
exit;;
esac
echo -e "\033[32m==================================================================\033[0m"
echo "正在开始安装Portainer并进行汉化："



docker run -d --restart=always --name="portainer" -p 9999:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v /root/public:/public jellyfina/portainer-ce


if [ "docker inspect --format '{{.State.Running}}' portainer" != "true" ]
then {
echo -e "\033[32m==================================================================\033[0m"
echo -e "portainer部署成功，使用外网访问管理地址时请先做好 \033[31m端口映射\033[0m"
echo -e "\033[32m==================================================================\033[0m"
echo -e "\033[31m外网管理地址:\033[0m http://$address:9999 "
echo -e "\033[31m内网管理地址:\033[0m http://$ip:9999 "
echo -e "\033[32m==================================================================\033[0m"
}
else
{
    echo "抱歉，portainer安装失败，请尝试多运行几次脚本或者检查网络是否正常"
}
fi

