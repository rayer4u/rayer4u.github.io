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

``` bash
apt install docker.io docker-compose python3-pip python3-setuptools
cp daemon.json /etc/docker/
service docker restart
```

## 安装seafile

```shell
cd omv/certs

# 或者nginx自签名证书。要指定正确的地址，后续seafile使用。或者拷贝正式证书改名
gencert.sh

# 配置.env
cd ..
mv .env.sample .env
vim .env

# ddns
pip3 install dnspod-python python-dotenv

# 一键启动所有服务
docker-compose up -d

# fuse mount，需要源系统支持，并修改docker-compose 打开相关权限
> mkdir /mnt/aaa
> ./seaf-fuse.sh start /mnt/aaa

```

## seafile

[社区版专业版转换](https://manual-cn-origin.seafile.com/deploy_pro/migrate_from_seafile_community_server)，docker版只用其中的migrate

### storage切换minio

存储改成对象存储，可以利用其分布式特性

1. seafile.conf添加配置

    ``` seafile.conf
    [commit_object_backend]
    name = s3
    bucket = my-commit-objects
    key_id = minio1
    key = minio123
    host = minio:9000
    path_style_request = true
    memcached_options = --SERVER=memcached --POOL-MIN=10 --POOL-MAX=100

    [fs_object_backend]
    name = s3
    bucket = my-fs-objects
    key_id = minio1
    key = minio123
    host = minio:9000
    path_style_request = true
    memcached_options = --SERVER=memcached --POOL-MIN=10 --POOL-MAX=100

    [block_backend]
    name = s3
    bucket = my-block-objects
    key_id = minio1
    key = minio123
    host = minio:9000
    path_style_request = true
    memcached_options = --SERVER=memcached --POOL-MIN=10 --POOL-MAX=100
    ```

2. 重启服务，工具准备

    ``` bash
    # mc
    > docker run -it --rm --entrypoint=/bin/sh minio/mc

     ## **自行**下载minio的mc工具，放置到seafile配置目录，
    cp seafile/mc  omv_seafile_1:/usr/bin/

    # 自制seafile的本地文件目录格式->s3文件目录格式转换工具
    cp seafile/seafile_minio.mv.sh:/usr/bin/
    ```

3. 进行已有数据迁移

    ``` bash
    # 进入seafile镜像
    docker-compose exec seafile bash

    # 创建minio的客户端快捷访问
    > mc alias set minio http://minio:9000 minio1 minio123 --api s3v4

    # 进行seafile已有文件迁移
    > mc cp -r  blocks/* minio/my-block-objects/
    > mc cp -r commits/* minio/my-commit-objects/
    > mc cp -r fs/* minio/my-fs-objects/

    # 迁移的格式进行转换
    > bash seafile_minio_mv.sh minio/my-commit-objects/
    > bash seafile_minio_mv.sh minio/my-fs-objects/
    > bash seafile_minio_mv.sh minio/my-block-objects/
    ```

## gogs

## 备份恢复

```
mysqldump -u root -p --all-databases > alldb.sql
mysql   --protocol=tcp --host=127.0.0.1 --user=root --port=3306 --default-character-set=utf8 --comments --database=ccnet_db  < "/home/ray/develop/working/my/rayer4u.github.io/omv/alldb.sql"

mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --opt ccnet_db > ccnet_db.sql.`date +"%Y-%m-%d-%H-%M-%S"`
mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --opt seafile_db > seafile_db.sql.`date +"%Y-%m-%d-%H-%M-%S"`
mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --opt seahub_db > seahub_db.sql.`date +"%Y-%m-%d-%H-%M-%S"`

mysql -uroot -p$MYSQL_ROOT_PASSWORD ccnet_db < ccnet_db.sql.2020-11-19-06-57-36
mysql -uroot -p$MYSQL_ROOT_PASSWORD seafile_db < seafile_db.sql.2020-11-19-06-57-10
mysql -uroot -p$MYSQL_ROOT_PASSWORD seahub_db < seahub_db.sql.2020-11-19-06-57-59

rsync -az /data/haiwen /backup/data

conf/seahub_settings.py
MAX_NUMBER_OF_FILES_FOR_FILEUPLOAD
```

## 参考

- [Setup With Amazon S3](https://manual.seafile.com/deploy_pro/setup_with_amazon_s3/)