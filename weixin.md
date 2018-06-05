# angular应用在ios里的wx.config遇到invalid signature问题

按照[官方文档](https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421141115)描述。“对于变化url的SPA的web app可在每次url变化时进行调用“。angular实现在component的ngafterviewinit里调用微信jsapi接口。代码如下
```
            this.requestJSSDK().subscribe((js) => {

                const _jsapi_ticket = js.ticket;
                const _timestamp = Math.round(new Date().getTime() / 1000);
                const _noncestr = Math.random().toString(36).substr(2, 15);
                let _url;
                if (platformIsiOS() && isFirstRun()) {
                    if (platformIsWeChat_Person()) {
                        _url = getsdkUrl();
                    } else if (platformIsWeChat_Worke()) {
                        _url = decodeURIComponent(wx.getC().url);
                    }
                } else {
                    // alert("非iOS");
                    _url = location.href.split('#')[0];
                }
                // alert("最终url" + _url);
                const ret = {
                    jsapi_ticket: _jsapi_ticket,
                    noncestr: _noncestr,
                    timestamp: _timestamp,
                    url: _url,
                };
                const string = raw(ret);
                const _signature = CryptoJS.SHA1(string).toString();
                wx.config({
                    debug: false, // 开启调试模式
                    appId: getWeChatAppId(), // 必填，企业号的唯一标识，此处填写企业号corpid
                    timestamp: _timestamp, // 必填，生成签名的时间戳
                    nonceStr: _noncestr, // 必填，生成签名的随机串
                    signature: _signature, // 必填，签名
                    jsApiList: [
                        'checkJsApi',
                        'scanQRCode',
                        'closeWindow'],
                });

                wx.ready(() => {
                });

                // 临时调试信息
                wx.error((res) => {
                    // alert(this.T('微信接口初始化失败，如需使用二维码功能，请关闭界面再进。请让ios及微信版本保持最新'));
                    // alert(JSON.stringify(res));
                    // alert(_url);
                });

            }, (e) => console.error(e));                
```
理论上只用以下代码来作验证。android采用以下代码一切正常。
```
_url = location.href.split('#')[0];
```
ios的微信无法正确判断当前的url。因此我们做了很多特殊处理，也无法处理所有情况。似乎，ios的微信对于url的变更监控只在url跳转到稳定界面后就不再有效了。
