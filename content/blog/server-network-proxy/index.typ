#import "../../index.typ": template, tufted
#show: template.with(title: "服务器使用网络代理")

= 服务器使用网络代理

有的内网服务器不能通过网络访问到外网，如果要在服务器上使用一些代理编码工具，就需要一些网络设置。

总体的思路如下：
+ 本地端：在建立 ssh 连接时，使用反向端口转发（或者叫远程端口转发，Remote Forward），把服务器端对某个端口的访问转发到本地的某个端口；
+ 服务器端：设置代理，将 http 和 https 流量指向上面设置的端口。

需要注意，反向端口转发可能与服务器的配置有关，有的服务器可能不允许建立这样的连接。

== 本地端设置

ssh 命令中使用 `-R` 选项，例如
```bash
ssh -R 9999:localhost:6789 username@server
```
其中 `9999` 是服务器端的端口，`localhost:6789` 是本地端口（即 SSH 客户端这一侧），发到 `9999` 端口的流量会转到 `localhost:6789`。

也可以在 `~/.ssh/config` 里面进行配置
```config
Host server
  HostName server_IP
  User username
  RemoteForward 9999 127.0.0.1:6789
```


== 服务端设置

服务端需要做的是把 http 和 https 的流量指向前面设置好的 9999 端口。可以使用环境变量 `http_proxy` 和 `https_proxy`。可以在`.bashrc`上进行如下配置
```bashrc
proxy_on() {
  export http_proxy=http://localhost:9999
  export https_proxy=http://localhost:9999
  echo "Proxy has been set to localhost:9999"
}

proxy_off() {
  unset http_proxy https_proxy
  echo "Proxy has been disabled"
}
```
这样，只要在终端执行 `proxy_on` 即可开启代理。

如果使用 VSCode 这样的编辑器，通过 Remote-SSH 连接到服务器，那么它可能需要单独的设置。在 `Settings -> Remote [SSH:server]` 里面，搜索 Http: Proxy 选项，将其设置为 `http://127.0.0.1:9999`。

Http: Proxy 配置的说明如下：
The proxy setting to use. If not set, will be inherited from the `http_proxy` and `https_proxy` environment variables. When during remote development the Http: Use Local Proxy Configuration setting is disabled this setting can be configured in the local and the remote settings separately.

在配置好后，可以通过 `curl -I http://www.google.com` 这样的命令来检查流量是否通过我们制定的方式转发。
