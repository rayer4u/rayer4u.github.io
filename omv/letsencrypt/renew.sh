#/bin/bash
base_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$base_path"
source .env
id=$(docker compose run -d  -u$(id -u):$(id -g) renew)
ret=$(docker wait $id)
if [ $ret == 0 ]
then
  # 成功则进行证书更新检查和处理服务，并删除相应已完成容器
  python3 cert_change_update.py ${HOST_CERT_DIR}/live/${DOMAIN}/fullchain.pem
  docker rm $id
fi