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

## 安装omv-extres

```
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
```

## ddns

需要你是外网动态ip，并采用了dnspod来做dns解析才使用

```bash
cd ddns
mv .env.sample .env
vim .env
crontab -e
*/5 * * * * python3 /root/omv/ddns/ddns.py >> /root/omv/ddns/ddns.log 2>&1
```

## 安装docker

```
apt install docker.io docker-compose bash-completion python3-pip python3-setuptools
cp daemon.json /etc/docker/
service docker restart
```

## 安装seafile

```shell
cd omv/certs

# nginx自签名证书。要指定正确的地址，后续seafile使用
gencert.sh

# 配置.env
cd ..
mv .env.sample .env
vim .env

# ddns
pip3 install dnspod-python python-dotenv

# 一键启动所有服务
docker-compose up -d
```

## seafile

[社区版专业版迁移](https://manual-cn-origin.seafile.com/deploy_pro/migrate_from_seafile_community_server)，docker版只用其中的migrate

## gogs

## 备份恢复

```
mysqldump -u root -p --all-databases > alldb.sql
mysql   --protocol=tcp --host=127.0.0.1 --user=root --port=3306 --default-character-set=utf8 --comments --database=ccnet_db  < "/home/ray/develop/working/my/rayer4u.github.io/omv/alldb.sql"

mysqldump -h [mysqlhost] -u[username] -p[password] --opt ccnet-db > /backup/databases/ccnet-db.sql.`date +"%Y-%m-%d-%H-%M-%S"`
mysqldump -h [mysqlhost] -u[username] -p[password] --opt seafile-db > /backup/databases/seafile-db.sql.`date +"%Y-%m-%d-%H-%M-%S"`
mysqldump -h [mysqlhost] -u[username] -p[password] --opt seahub-db > /backup/databases/seahub-db.sql.`date +"%Y-%m-%d-%H-%M-%S"`

mysql -u[username] -p[password] ccnet-db < ccnet-db.sql.2013-10-19-16-00-05
mysql -u[username] -p[password] seafile-db < seafile-db.sql.2013-10-19-16-00-20
mysql -u[username] -p[password] seahub-db < seahub-db.sql.2013-10-19-16-01-05
```

## 参考
