#/bin/bash
base_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$base_path"
source .env
docker-compose run -u$(id -u):$(id -g) --rm renew
python3 cert_change_update.py ${HOST_CERT_DIR}/live/${DOMAIN}/fullchain.pem
