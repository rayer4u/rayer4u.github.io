# 安装omv

使用最新的iso``安装。默认用户admin/openmediavault。deiban系统的账号会在安装过程中提示输入，用来ssh

## 系统升级

```shell
# 设置网络dns
vim  /etc/network/interfaces
vim /etc/resolv.conf 
service networking restart

# 更换源。参考[源](https://cloud.tencent.com/developer/article/1590080)
sed -i 's#http://deb.debian.org#https://mirrors.163.com#g' /etc/apt/sources.list
apt update
apt upgrade


```

## 安装docker

```
apt install docker.io docker-compose bash-completion
cp daemon.json /etc/docker/
service docker restart
```

## 安装omv-extres

```
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
```

## 

```shell
cd omv/certs

# nginx自签名证书。要指定正确的地址，后续seafile使用
gencert.sh

# 配置
cd ..
mv .env.sample .env
vim .env

# 一键启动所有服务
docker-compose up -d
```

## seafile

[社区版专业版迁移](https://manual-cn-origin.seafile.com/deploy_pro/migrate_from_seafile_community_server)，docker版只用其中的migrate
```


```


## gogs

## 参考
