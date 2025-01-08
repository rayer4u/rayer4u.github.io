# ddns

dnspod支持。参照了[dnspod-shell](https://github.com/anrip/dnspod-shell)和[dnspod-ddns](https://github.com/strahe/dnspod-ddns)的结构并使用了其中的get_ip.py。重写目的是减少请求数，并去掉了自行调度，调度采用crontab
支持多子域名,具体详见`.env.sample`

```shell
# 依赖
pip3 install dnspod-python python-dotenv

# 定时调用，以下每5分钟
crontab -e
*/5 * * * * python3 /root/omv/ddns/ddns.py >> /root/omv/ddns/ddns.log 2>&1

# 查看更新日志
cat ddns.log  | grep -B 5 Updated
```
