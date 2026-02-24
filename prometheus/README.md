# prometheus

## blackbox

```
# 本机测试blackbox
curl "http://127.0.0.1:9115/probe?module=https_2xx&target=https://roybi.net:8920/"

# 如果blackbox被gfw拦截，docker-compose.yml里采用本地编译的镜像，以变更指纹
blackbox_exporter:local
```

