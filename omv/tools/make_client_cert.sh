#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_KEY="$DIR/ca.key"
CA_CRT="$DIR/ca.crt"

# 1. 初始化自建根 CA (如果不存在)
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CRT" ]; then
    echo "正在初始化自建根 CA..."
    openssl genrsa -out "$CA_KEY" 4096
    openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
        -out "$CA_CRT" -subj "/C=CN/ST=Guangdong/L=Shenzhen/O=OMV/OU=Home/CN=OMV-Internal-CA"
    echo "根 CA 已就绪: $CA_CRT"
fi

CLIENT_NAME="${1:-myphone}"
CLIENT_KEY="$DIR/${CLIENT_NAME}.key"
CLIENT_CSR="$DIR/${CLIENT_NAME}.csr"
CLIENT_CRT="$DIR/${CLIENT_NAME}.crt"
CLIENT_EXT="$DIR/${CLIENT_NAME}.ext"
CLIENT_P12="$DIR/${CLIENT_NAME}.p12"

echo "1. 生成客户端私钥与证书..."
openssl genrsa -out "$CLIENT_KEY" 2048
openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/C=CN/O=OMV/CN=${CLIENT_NAME}"

# 关键扩展：必须显式声明 clientAuth 扩展用途，否则 Android/iOS 拒绝将其作为客户端身份证书导入
cat << 'EOF' > "$CLIENT_EXT"
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl x509 -req -in "$CLIENT_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
    -out "$CLIENT_CRT" -days 1095 -sha256 -extfile "$CLIENT_EXT"

echo "2. 打包为手机/移动端 100% 兼容的 PKCS#12 (.p12) 格式 (带 CA 链 + 传统加密兼容)..."
# 关键兼容参数：
# 1) -certfile "$CA_CRT": 必须打包根 CA 链，否则手机报“缺少颁发者证书”
# 2) -legacy: 适配 Android/iOS 底层 KeyStore，避免 OpenSSL 3.x 默认 PBES2/AES 加密导致手机解析报密码错误
openssl pkcs12 -export \
    -legacy \
    -in "$CLIENT_CRT" \
    -inkey "$CLIENT_KEY" \
    -certfile "$CA_CRT" \
    -name "$CLIENT_NAME" \
    -out "$CLIENT_P12" \
    -password pass:123456

# 清理临时文件
rm -f "$CLIENT_CSR" "$CLIENT_EXT"

echo "=========================================================="
echo "手机兼容版用户证书已成功生成！"
echo "证书文件: $CLIENT_P12"
echo "安装密码: 123456"
echo "=========================================================="
