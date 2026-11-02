// NJS 播放服务：隐藏真实全路径、文件名随机化与 4 小时安全签名校验
function xorEncrypt(text, key) {
    var textBuf = Buffer.from(text, 'utf8');
    var keyBuf = Buffer.from(key, 'utf8');
    var out = Buffer.alloc(textBuf.length);
    for (var i = 0; i < textBuf.length; i++) {
        out[i] = textBuf[i] ^ keyBuf[i % keyBuf.length];
    }
    return out.toString('base64url');
}

function xorDecrypt(b64url, key) {
    var cipherBuf = Buffer.from(b64url, 'base64url');
    var keyBuf = Buffer.from(key, 'utf8');
    var out = Buffer.alloc(cipherBuf.length);
    for (var i = 0; i < cipherBuf.length; i++) {
        out[i] = cipherBuf[i] ^ keyBuf[i % keyBuf.length];
    }
    return out.toString('utf8');
}

// 签发 API：生成标准优雅的 RESTful 目录层级 URL: /play/<token>/<expires>/<md5>/<random>.mp4
function getSign(r) {
    var uri = r.args.uri;
    if (!uri) {
        r.headersOut['Content-Type'] = 'application/json; charset=utf-8';
        r.return(400, JSON.stringify({ error: "Missing uri parameter" }));
        return;
    }

    var secret = r.variables.sec_key || "omv_video_secret_key";
    var expires = Math.floor(Date.now() / 1000) + 14400; // 4 个小时有效 (14400s)
    var encKey = secret + "_" + expires;

    var ext = uri.lastIndexOf('.') !== -1 ? uri.substring(uri.lastIndexOf('.')) : '.mp4';
    var crypto = require('crypto');
    var randomFilename = crypto.createHash('md5')
                               .update(uri + expires + Math.random().toString())
                               .digest('hex')
                               .substring(0, 10) + ext;

    // 对真实相对全路径进行密钥混淆加密
    var token = xorEncrypt(uri, encKey);

    // 计算防篡改签名
    var md5 = crypto.createHash('md5').update(expires + token + secret).digest('base64url');

    // 格式: /play/<token>/<expires>/<md5>/<random_name>.<ext>
    // 纯斜杠层级，无任何特殊符号，末尾是纯粹的文件名与扩展名
    var cleanPlayUrl = "/play/" + token + "/" + expires + "/" + md5 + "/" + randomFilename;

    r.headersOut['Content-Type'] = 'application/json; charset=utf-8';
    r.return(200, JSON.stringify({
        url: cleanPlayUrl,
        expires: expires,
        ttl: 14400
    }));
}

// 播放网关：解析 /play/ 请求，解构斜杠路径参数
function handlePlay(r) {
    var token = r.args.token;
    var expires = parseInt(r.args.expires || "0", 10);
    var md5 = r.args.md5;
    var secret = r.variables.sec_key || "omv_video_secret_key";

    // 优先从优雅斜杠路径 /play/<token>/<expires>/<md5>/<filename> 中解构
    if (!token || !expires || !md5) {
        var parts = r.uri.replace(/^\/+|\/+$/g, '').split('/');
        // parts 结构: ['play', token, expires, md5, filename]
        if (parts.length >= 5 && parts[0] === 'play') {
            token = parts[1];
            expires = parseInt(parts[2], 10);
            md5 = parts[3];
        }
    }

    if (!token || !expires || !md5) {
        r.return(403, "Missing security token");
        return;
    }

    // 1. 严格检查时效
    var now = Math.floor(Date.now() / 1000);
    if (now > expires) {
        r.return(410, "Link expired");
        return;
    }

    // 2. 检查防篡改签名
    var crypto = require('crypto');
    var expectedMd5 = crypto.createHash('md5').update(expires + token + secret).digest('base64url');
    if (expectedMd5 !== md5) {
        r.return(403, "Invalid signature");
        return;
    }

    // 3. 解密真实全路径
    var encKey = secret + "_" + expires;
    var realUri = "";
    try {
        realUri = xorDecrypt(token, encKey);
    } catch(e) {
        r.return(403, "Invalid token format");
        return;
    }

    // 4. 安全防护：防目录穿越攻击
    if (realUri.indexOf('..') !== -1 || !realUri.startsWith('/')) {
        r.return(403, "Illegal path access");
        return;
    }

    // 5. 内部重定向给底层静态文件服务
    r.internalRedirect("/_internal_media/" + realUri.substring(1));
}

export default { getSign, handlePlay };
