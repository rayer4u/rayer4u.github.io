# 使用
适用于dnspod的域名申请、更新

```
# 有更新时编译镜像
# docker build . -t rayer4u/certbot-dnspod

cp .env.sample .env

# 增加一个域名需要执行。xxxxx.com需要按照需要变更
vim .env
source .env
mkdir -p ${HOST_CERT_DIR}
vim ${HOST_CERT_DIR}/${DOMAIN}.txt
chmod 700 ${HOST_CERT_DIR}/${DOMAIN}.txt

docker-compose run -u$(id -u):$(id -g) --rm certonly

# 后续刷新
docker-compose run -u$(id -u):$(id -g) --rm renew

```
