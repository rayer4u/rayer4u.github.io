#

- [deploy_seafile_pro_with_docker](https://manual.seafile.com/docker/pro-edition/deploy_seafile_pro_with_docker/)

## db

mariadb:10.5 -> mariadb:10.6

```bash
$docker-compose up -d db
$docker-compose exec db bash
  $mariadb-upgrade -p$MYSQL_ROOT_PASSWORD

```

## elasticsearch

seafileltd/elasticsearch-with-ik:5.6.16 -> elasticsearch:7.16.2

```
# 删除文件
```
