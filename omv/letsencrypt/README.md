# acme.sh 证书中心

基于官方 `neilpang/acme.sh` 容器镜像构建的独立泛域名 SSL 证书申请与自动化续期中心。  
申请完成后统一导出标准证书（`fullchain.pem` 与 `privkey.pem`）至公共目录 `HOST_CERT_DIR`（默认 `omv/certs`），供 Traefik、Nginx 或其他业务网关只读消费。

---

## 一、 快速使用流水线

### 1. 配置云厂商凭据与环境
复制样例配置文件：
```bash
cd omv/letsencrypt
cp .env.sample .env
```
编辑 `.env`，填入域名及对应云厂商凭据。

#### 环境变量命名精准对照表（严禁写错大小写）
| 云厂商/凭据类型 | 对应插件名 | 必须填写的变量名 | 格式特征示例 |
| :--- | :--- | :--- | :--- |
| **DNSPod Token (推荐)** | `dns_dp` | **`DP_Id`**<br>**`DP_Key`** | ID 为纯数字（如 `193411`）<br>Key 为 32 位 Token（如 `9b86505b...`） |
| **腾讯云全局 API 密钥** | `dns_tencent` | **`Tencent_SecretId`**<br>**`Tencent_SecretKey`** | SecretId 通常以 `AKID...` 开头 |
| **阿里云 DNS** | `dns_ali` | **`Ali_Key`**<br>**`Ali_Secret`** | 阿里云 AccessKey ID 与 Secret |
| **Cloudflare** | `dns_cf` | **`CF_Token`**<br>**`CF_Account_ID`** | Cloudflare 专属 API Token |

> **提示**：修改 `.env` 之后，若容器已在运行，必须重新加载以注入环境变量：
> ```bash
> docker compose up -d --force-recreate
> ```

---

### 2. 启动常驻证书守护容器
```bash
docker compose up -d
```
> 容器内置 `daemon` 模式，每日会自动检测证书状态并执行静默续期。

---

### 3. 首次签发泛域名证书（仅需执行一次）

推荐在首次使用时将默认 CA 设为 **Let's Encrypt**（免除 ZeroSSL 强制注册邮箱与国内网络连接超时的暗坑）：

```bash
# 全局切回 letsencrypt 为默认 CA
docker compose exec acme-sh acme.sh --set-default-ca --server letsencrypt
```

根据你的 DNS 提供商执行对应签发命令：

#### 选项 A：使用 DNSPod Token（最常用）
```bash
docker compose exec acme-sh acme.sh --issue \
  --server letsencrypt \
  --dns dns_dp \
  -d roybi.net \
  -d *.roybi.net \
  --force
```
*(注意：插件名是 **`dns_dp`**，切勿写成 `dns_dnspod`)*

#### 选项 B：使用腾讯云全局 SecretId / SecretKey
```bash
docker compose exec acme-sh acme.sh --issue \
  --server letsencrypt \
  --dns dns_tencent \
  -d roybi.net \
  -d *.roybi.net \
  --force
```

#### 选项 C：使用阿里云 DNS
```bash
docker compose exec acme-sh acme.sh --issue \
  --server letsencrypt \
  --dns dns_ali \
  -d roybi.net \
  -d *.roybi.net \
  --force
```

#### 选项 D：使用 Cloudflare
```bash
docker compose exec acme-sh acme.sh --issue \
  --server letsencrypt \
  --dns dns_cf \
  -d roybi.net \
  -d *.roybi.net \
  --force
```

> **成功标志**：终端最后打印出 `Cert success.`，且明确提示证书与 fullchain 生成路径。

---

### 4. 安装并导出证书至公共目录（仅需执行一次）

由于新版 `acme.sh` 默认生成更安全高效的 ECC 椭圆曲线证书，导出时**必须显式声明 `--ecc`**：

```bash
docker compose exec acme-sh acme.sh --install-cert \
  --ecc \
  -d roybi.net \
  -d *.roybi.net \
  --key-file /certs/privkey.pem \
  --fullchain-file /certs/fullchain.pem \
  --reloadcmd "chown -R 1000:1000 /certs && chmod 600 /certs/privkey.pem"
```

> **参数与权限说明**：
> - `--ecc`：指定提取 ECC 证书（对应 `roybi.net_ecc` 目录）；
> - `--reloadcmd "chown -R 1000:1000 /certs && chmod 600 /certs/privkey.pem"`：
>   - **严格安全基线**：私钥权限维持绝对安全的 `600`（避免很多严格模式的服务如 Traefik 因 `permissions are too open` 拒绝启动）；
>   - **属主适配**：由于 `acme-sh` 容器以 root 运行，导出的证书属主默认为 root。通过 `chown -R 1000:1000` 将所有者移交给普通用户（UID 1000，如 Traefik、Nginx），确保非 root 容器能够安全读取 `600` 私钥。

---

## 二、 自动化续期机制

1. **凭据自动固化**：首次通过 `--dns` 签发成功后，`acme.sh` 会自动将 DNS API 凭据持久化存入数据卷中的 `/acme.sh/account.conf`；
2. **静默滚动续期**：后台容器每日检测，当证书剩余不足 30 天时，自动调用已保存的 DNS API 重新验证签发；
3. **自动覆盖与权限执行**：签发后自动覆盖更新 `/certs` 下的证书并执行 `--reloadcmd`；
4. **无需配置宿主机 Crontab**，全生命周期在容器内闭环。

---

## 三、 常见故障排查速查（FAQ）

#### Q1: 提示 `Cannot find DNS API hook for: dns_dnspod`
- **根因**：插件名拼写错误，`acme.sh` 没有名为 `dns_dnspod` 的脚本。
- **解决**：改用 `--dns dns_dp`（针对 DNSPod Token）或 `--dns dns_tencent`（针对腾讯云密钥）。

#### Q2: 提示 `Please update your account with an email address first`
- **根因**：当前默认 CA 是商业版 ZeroSSL，要求强制注册绑定邮箱。
- **解决**：在申请命令中增加 `--server letsencrypt`，或执行 `acme.sh --set-default-ca --server letsencrypt`。

#### Q3: 提示 `cat: .../fullchain.cer: No such file or directory`
- **根因 1**：上一步 `--issue` 根本没有真正成功签发，目录里只有本地生成的 `.key` 和 `.csr`，没有 `.cer`。
- **根因 2**：签发的是 ECC 证书，而 `--install-cert` 时漏掉了 `--ecc` 参数。
- **排查命令**：
  ```bash
  # 检查容器内是否真正存在可用证书
  docker compose exec acme-sh acme.sh --list
  ```
