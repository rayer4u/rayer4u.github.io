# ddns

dnspod支持。参照了[dnspod-shell](https://github.com/anrip/dnspod-shell)和[dnspod-ddns](https://github.com/strahe/dnspod-ddns)的结构并使用了其中的get_ip.py。重写目的是减少请求数，并去掉了自行调度，调度采用crontab

```shell
pip3 install dnspod-python python-dotenv
```
