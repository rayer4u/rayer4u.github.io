# HYPER-V虚拟设置

```
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=22 connectaddress=xxx.xxx.xxx.xxx connectport=22

```

## 参考

- [设置 NAT 网络](https://docs.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/user-guide/setup-nat-network)
- [设置端口映射](https://docs.microsoft.com/en-us/powershell/module/netnat/add-netnatstaticmapping?view=win10-ps)
- [如何用笔记本ssh连接局域网内其他电脑上的wsl2 ubuntu](https://zhuanlan.zhihu.com/p/357038111)