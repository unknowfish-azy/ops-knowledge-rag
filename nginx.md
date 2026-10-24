---
title: nginx 运维笔记
tags: [nginx, 编译安装, 虚拟主机, 反向代理, 负载均衡, 动静分离]
category: 运维/中间件
updated: 2026-10-24
---

# nginx 运维笔记

> 从源码编译安装到反向代理、负载均衡、动静分离的完整实操记录。
> 原稿中的拼写错误与配置笔误已修正，勘误清单见[附录 A](#附录-a勘误清单)。

## 0. 实验环境

| 角色 | IP | 用途 |
| --- | --- | --- |
| 代理服务器 | 192.168.229.136 | 对外监听 80，转发请求 |
| 真实服务器 | 192.168.229.140 | 静态站点 / 实验站点一 |
| 真实服务器 | 192.168.229.150 | 动态站点 / 实验站点二 |

- 系统：CentOS 7，全部操作在 root 下进行
- 每台机器实验前统一关闭防火墙与 selinux：

```bash
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

---

# 1. nginx 编译安装（二进制源码包安装）

## 1.1 安装编译环境

```bash
[root@admin ~]# yum -y install gcc gcc-c++
```

## 1.2 安装软件包及插件

```bash
[root@admin ~]# yum -y install pcre pcre-devel
```

## 1.3 安装 openssl 与 zlib

```bash
[root@admin ~]# yum -y install openssl openssl-devel zlib
```

## 1.4 创建运行用户

```bash
[root@admin ~]# useradd nginx
```

> 建议加上 `-s /sbin/nologin`，让该账号只用于运行服务、不能登录系统：
> `useradd -s /sbin/nologin nginx`

## 1.5 下载源码并编译安装

```bash
# 下载源码包（本例使用 1.16.0，生产环境建议换成当前稳定版）
[root@admin ~]# wget http://nginx.org/download/nginx-1.16.0.tar.gz

# 解压到指定目录
[root@admin ~]# tar xzf nginx-1.16.0.tar.gz -C /usr/local/
[root@admin ~]# cd /usr/local/nginx-1.16.0/

# 进行服务自定义设置
[root@admin nginx-1.16.0]# ./configure --prefix=/usr/local/nginx \
  --user=nginx --group=nginx \
  --sbin-path=/usr/local/nginx/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/tmp/nginx/client_body \
  --http-proxy-temp-path=/tmp/nginx/proxy \
  --http-fastcgi-temp-path=/tmp/nginx/fastcgi \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/lock/nginx \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-pcre \
  --with-http_realip_module \
  --with-stream

# 进行编译
[root@admin nginx-1.16.0]# make && make install

# 查看 nginx 版本与编译参数
[root@admin nginx-1.16.0]# /usr/local/nginx/sbin/nginx -V
```

> `-v` 只显示版本号，`-V` 才会打印完整的编译参数，验证模块有没有编进去用 `-V`。

### configure 参数说明

| 参数 | 作用 |
| --- | --- |
| `--prefix=/usr/local/nginx` | 指定安装目录 |
| `--user=nginx` | 指定运行用户 |
| `--group=nginx` | 指定运行用户组 |
| `--conf-path=/etc/nginx/nginx.conf` | 配置文件路径 |
| `--error-log-path=/var/log/nginx/error.log` | 错误日志路径 |
| `--http-log-path=/var/log/nginx/access.log` | 访问（正确）日志路径 |
| `--http-client-body-temp-path=/tmp/nginx/client_body` | http 客户端请求临时文件存放路径 |
| `--http-proxy-temp-path=/tmp/nginx/proxy` | http 代理临时文件路径 |
| `--http-fastcgi-temp-path=/tmp/nginx/fastcgi` | fastcgi 临时文件存放路径 |
| `--pid-path=/var/run/nginx.pid` | 指定 pid 文件 |
| `--lock-path=/var/lock/nginx` | 指定 lock 文件 |
| `--with-http_stub_status_module` | 获取 nginx 自上次启动以来的状态 |
| `--with-http_ssl_module` | 启用 ssl |
| `--with-http_gzip_static_module` | 在线实时压缩输出流 |
| `--with-pcre` | 编译包含 pcre（正则支持） |
| `--with-http_realip_module` | 允许从请求表头更改客户端的真实 IP 地址值，默认关闭 |
| `--with-stream` | 支持 tcp / udp 四层代理 |

## 1.6 配置文件详解

```bash
[root@admin ~]# vim /etc/nginx/nginx.conf
```

```nginx
# 全局配置
#user  nobody;                      # 运行用户，默认是 nobody；本例 configure 时已指定 nginx
worker_processes  1;                 # nginx 启动进程数量，一般与逻辑 CPU 数量相同

events {
    worker_connections  1024;        # 单个进程的最大并发连接数
}

# http 网站服务相关设置
http {
    include       mime.types;
    default_type  application/octet-stream;

    #access_log  logs/access.log  main;   # 访问日志的位置和格式

    sendfile        on;              # 是否调用 sendfile 函数输出文件。
                                     # 一般设为 on；若 nginx 承担大量磁盘 IO，可设为 off 以降低系统负载

    #keepalive_timeout  0;
    keepalive_timeout  65;           # 长连接超时时间

    #gzip  on;                       # 是否开启 gzip 压缩

    server {
        listen       80;             # 监听端口
        server_name  localhost;      # 绑定的主机名、域名或 IP
        #charset koi8-r;             # 编码字符集

        location / {
            root   html;                          # 网站根目录
            index  index.html index.htm;          # 默认首页文档
        }

        error_page   500 502 503 504  /50x.html;  # 错误状态返回页面

        location = /50x.html {
            root   html;
        }

        # 与 php 服务配合使用时启用
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # php 服务（fastcgi 方式）
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}
    }

    # 虚拟主机（一台服务器一个 nginx 服务，上线多个网站时使用）
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;
    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

    # https 配置
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;
    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;
    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;
    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
}
```

### nginx.conf 的结构组成

`nginx.conf` 由 **全局块、events 块、http 块** 三部分组成。

- http 块内部又包含 **http 全局块**、**多个 server 块**
- 每个 server 块内还可以包含 **server 全局块**和**多个 location 块**

各配置块之间是嵌套关系，同一层级内的指令**没有先后次序要求**。

## 1.7 校验配置并启动

```bash
# 检查配置文件语法
[root@admin ~]# /usr/local/nginx/sbin/nginx -t

# 首次启动前，按 configure 里的临时目录参数先把目录建好
[root@admin ~]# mkdir -p /tmp/nginx
[root@admin ~]# mkdir -p /usr/local/nginx/logs

# 启动
[root@admin ~]# /usr/local/nginx/sbin/nginx
```

## 1.8 常用命令

```bash
nginx -c /path/nginx.conf           # 以指定目录下的配置文件启动 nginx
nginx -s reload                     # 修改配置后重新加载生效
nginx -s stop                       # 快速停止 nginx
nginx -s quit                       # 平滑停止（处理完当前请求再退出）
nginx                               # 直接启动
nginx -t                            # 测试当前配置文件是否正确
nginx -t -c /path/abc/nginx.conf    # 测试指定配置文件是否正确
```

### 加入开机自启（SysV 脚本方式）

```bash
chmod +x /etc/init.d/nginx
systemctl daemon-reload
```

> 这是把 SysV 启动脚本注册给 systemd 的做法。编译安装一般需要自己提供 `/etc/init.d/nginx`；
> 如果用 yum 安装的 nginx，系统已自带 unit 文件，直接 `systemctl enable nginx` 即可。

## 1.9 通过 nginx 上线静态代码

```bash
# 1、安装 nginx（见上文，过程略）
# 2、关闭防火墙与 selinux（见第 0 节）
# 3、上传代码并解压
[root@admin ~]# yum -y install unzip
[root@admin ~]# unzip zx70.zip

# 4、创建代码目录
[root@admin ~]# cp -r zx70 /

# 5、修改配置文件
[root@admin ~]# vim /etc/nginx/nginx.conf
```

```nginx
server {
    listen       80;
    server_name  localhost;
    location / {
        root   /zx70;
        index  index.html index.htm;
    }
}
```

```bash
# 6、停止 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx -s stop

# 7、启动 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx
```

---

# 2. nginx 虚拟主机

> 虚拟主机是一种特殊的软硬件技术，它可以把网络上的一台主机划分成多个虚拟主机，每个虚拟主机独立对外提供 www 服务，从而实现一台主机对外提供多个 web 服务。

nginx 支持三种类型的虚拟主机配置：

1. 基于**域名**的虚拟主机
2. 基于 **IP** 的虚拟主机
3. 基于**端口**的虚拟主机

## 2.1 基于域名的虚拟主机

```bash
# 1、修改配置文件
[root@admin ~]# vim /etc/nginx/nginx.conf
```

```nginx
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  web.yasuo.com;
        location / {
            root   /yasuo;
            index  index.html index.htm;
        }
    }

    server {
        listen       80;
        server_name  web.1017.com;
        location / {
            root   /zx70;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

```bash
# 2、上传代码包并解压
[root@admin ~]# unzip HTML.zip

# 3、创建代码存放目录
[root@admin ~]# cp -r HTML /yasuo

# 4、停止 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx -s stop

# 5、启动 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx
```

> **实验提示**：基于域名的方式必须让域名能解析到这台机器。
> 测试时可在客户端 hosts 文件里加两行，再分别访问 `http://web.yasuo.com` 和 `http://web.1017.com`：
> ```
> 192.168.229.136  web.yasuo.com
> 192.168.229.136  web.1017.com
> ```

## 2.2 基于 IP 的虚拟主机

```bash
# 1、创建新的 IP 地址
[root@admin ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:a9:bf:f2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.229.136/24 brd 192.168.229.255 scope global noprefixroute ens32
       valid_lft forever preferred_lft forever
    inet6 fe80::b5ad:a214:23c6:6636/64 scope link noprefixroute
       valid_lft forever preferred_lft forever

# 添加一个子接口地址
[root@admin ~]# ifconfig ens32:1 192.168.229.140/24
[root@admin ~]# ifconfig
ens32: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.229.136  netmask 255.255.255.0  broadcast 192.168.229.255
        inet6 fe80::b5ad:a214:23c6:6636  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:a9:bf:f2  txqueuelen 1000  (Ethernet)
        RX packets 212394  bytes 139555176 (133.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 180947  bytes 29454041 (28.0 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens32:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.229.140  netmask 255.255.255.0  broadcast 192.168.229.255
        ether 00:0c:29:a9:bf:f2  txqueuelen 1000  (Ethernet)

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 32  bytes 2592 (2.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 32  bytes 2592 (2.5 KiB)
        TX errors 0  dropped 0  overruns 0  frame 0
```

```bash
# 2、修改配置文件
[root@admin ~]# vim /etc/nginx/nginx.conf
```

```nginx
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  192.168.229.136;
        location / {
            root   /yasuo;
            index  index.html index.htm;
        }
    }

    server {
        listen       80;
        server_name  192.168.229.140;
        location / {
            root   /zx70;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

```bash
# 3、停止 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx -s stop

# 4、启动 nginx
[root@admin ~]# /usr/local/nginx/sbin/nginx
```

## 2.3 基于端口的虚拟主机

```bash
# 1、修改配置文件
[root@admin ~]# vim /etc/nginx/nginx.conf
```

```nginx
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;
        location / {
            root   /yasuo;
            index  index.html index.htm;
        }
    }

    server {
        listen       8080;
        server_name  localhost;
        location / {
            root   /zx70;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

```bash
# 2、检查配置文件语法
[root@admin ~]# /usr/local/nginx/sbin/nginx -t

# 3、重新加载配置文件
[root@admin ~]# /usr/local/nginx/sbin/nginx -s reload
```

---

# 3. nginx 代理

## 3.1 代理原理

常见的高可用 Web 架构中，对外的一层通常由 `nginx + keepalived` 承担负载均衡与代理职责，再向下转发到 H5 / 应用服务器。

### 正向代理与反向代理

**正向代理**：代理的是客户端。客户端把请求交给代理服务器，由代理代替客户端去访问目标服务，因此服务器不知道真实的客户端是谁。

> 例：访问 tiktok 时通过"科学上网"成功访问，tiktok 认为访问者位于代理服务器所在的位置。

**反向代理**：代理的是服务器。用户只知道代理服务器的地址，不知道背后真实的服务器是谁。

> 例：访问 baidu.com，用户并不关心后面是哪台机器在提供服务。

| 对比项 | 正向代理 | 反向代理 |
| --- | --- | --- |
| 代理对象 | 客户端 | 服务器 |
| 隐藏的是 | 真实客户端 | 真实服务器 |
| 客户端是否需配置 | 需要 | 不需要 |
| 典型场景 | 科学上网、内网穿透 | 负载均衡、动静分离 |

## 3.2 实验环境

| 角色 | IP |
| --- | --- |
| 代理服务器 | 192.168.229.136 |
| 真实服务器（提供网站内容） | 192.168.229.140 |

## 3.3 两台机器都需要的操作

```bash
# 1、关闭防火墙与 selinux（见第 0 节）

# 2、配置 nginx 官方 yum 源 —— 建议 yum 安装
[root@admin ~]# vim /etc/yum.repos.d/nginx.repo
```

```ini
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
```

```bash
# 3、安装 nginx
[root@admin ~]# yum -y install nginx
```

## 3.4 真实服务器操作

```bash
# 1、安装解压软件
[root@admin ~]# yum -y install unzip

# 2、上传代码包并解压
[root@admin ~]# unzip zx70.zip

# 3、创建代码目录
[root@admin ~]# cp -r zx70 /

# 4、修改配置文件
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
server {
    listen       80;
    server_name  localhost;
    location / {
        root   /zx70;
        index  index.html index.htm;
    }
}
```

```bash
# 5、启动 nginx 服务
[root@admin ~]# systemctl start nginx
```

## 3.5 代理服务器操作

```bash
# 1、修改配置文件
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
server {
    listen       80;
    server_name  localhost;

    location / {
        proxy_pass  http://192.168.229.140:80;
        proxy_set_header  Host  $http_host;
        proxy_set_header  X-Real-Ip  $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;

        proxy_connect_timeout  30;
        proxy_send_timeout     60;
        proxy_read_timeout     60;
    }
}
```

```bash
# 2、检查 nginx 语法格式
[root@admin ~]# nginx -t

# 3、重启 nginx 服务，使配置生效
[root@admin ~]# systemctl restart nginx

# 4、查看日志文件
[root@admin ~]# tail -f /var/log/nginx/access.log
```

### 常用 proxy 指令说明

| 指令 | 说明 |
| --- | --- |
| `proxy_pass` | 指定真实服务器地址，可以是 IP 也可以是域名 |
| `proxy_set_header Host` | 重新定义发往真实服务器的请求头 |
| `proxy_set_header X-Real-Ip` | 传递客户端真实地址 |
| `proxy_set_header X-Forwarded-For` | 记录经过的代理地址链 |
| `proxy_connect_timeout` | 与后端建立连接（发起三次握手）的等候响应超时时间 |
| `proxy_send_timeout` | 后端回传数据时，要求在该时间段内完成 |
| `proxy_read_timeout` | 读取后端数据超时，超过该时间未收到数据则关闭连接 |

---

# 4. nginx 负载均衡

如果 nginx 给两台 web 服务器做代理，采用轮询算法，那么当其中一台的 web 程序关闭、无法访问时，代理服务器仍然会把请求分发给这台不可用的机器。如果响应时间过长，用户就会一直卡在等待界面，体验很差。

负载均衡的作用就是：当后端某台真实服务器发生故障后，自动切换到能正常连接的服务器。

## 4.1 upstream 配置

`upstream` 用于定义一组被代理的服务器地址，并配置负载均衡算法，默认采用轮询。

```bash
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
upstream tcpsiz {
    server 192.168.229.140:80;
    server 192.168.229.150:80;
}

server {
    listen       80;
    server_name  localhost;

    location / {
        proxy_pass  http://tcpsiz;
    }
}
```

```bash
# 重启 nginx
[root@admin ~]# systemctl restart nginx
```

> 注意：`proxy_pass` 后面跟 upstream 名字时，`http://` 后面的名字必须与 `upstream` 定义的名字**完全一致**。

## 4.2 调度算法

upstream 支持 4 种负载均衡调度算法：

| 算法 | 说明 |
| --- | --- |
| 轮询（默认） | 每个请求按时间顺序逐一分配到不同的后端服务器 |
| `ip_hash` | 按客户端 IP 的 hash 结果分配，同一 IP 固定访问同一台服务器，可解决 session 问题 |
| `url_hash` | 按访问的 URL 结果分配，使同一 URL 定向到同一台后端，便于后端保留缓存、提高效率 |
| `fair` | 智能算法，依据页面大小和加载时间分配请求，响应时间短的优先分配。nginx 本身不支持，需额外安装 `upstream_fair` 模块 |

## 4.3 四种常见配置示例

### 轮询

nginx 分配的权重此时都为 1，处理请求的顺序为 **ABABABABAB**。

```nginx
upstream tcpsiz {
    server 192.168.229.140:80;
    server 192.168.229.150:80;
}

server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass  http://tcpsiz;
    }
}
```

```bash
[root@admin ~]# systemctl restart nginx
```

### 热备（backup）

两台服务器时，只有当其中一台发生故障，才会启用第二台对外提供服务。
请求顺序：**AAAAAAAAAAA** → A 故障后 → **BBBBBBBBBBBBB**

```nginx
upstream tcpsiz {
    server 192.168.229.140:80;
    server 192.168.229.150:80 backup;
}

server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass  http://tcpsiz;
    }
}
```

```bash
[root@admin ~]# systemctl restart nginx
```

### 加权轮询（weight）

按配置的权重大小分发；不设置时默认权重为 1。
下例权重 1:2，请求顺序为 **ABBABBABBABB**。

```nginx
upstream tcpsiz {
    server 192.168.229.140:80 weight=1;
    server 192.168.229.150:80 weight=2;
}

server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass  http://tcpsiz;
    }
}
```

```bash
[root@admin ~]# systemctl restart nginx
```

### ip_hash

nginx 会让相同客户端的请求始终落到同一台服务器。

```nginx
upstream tcpsiz {
    server 192.168.229.140:80;
    server 192.168.229.150:80;
    ip_hash;
}

server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass  http://tcpsiz;
    }
}
```

```bash
[root@admin ~]# systemctl restart nginx
```

## 4.4 server 状态参数

| 参数 | 说明 |
| --- | --- |
| `down` | 表示该机器暂时不参与负载均衡 |
| `backup` | 预留的备份机器。其他非 backup 机器故障或繁忙时才会收到请求，因为该机器负载压力最低 |
| `max_fails` | 允许请求失败的次数，默认 1；超过该次数则返回错误 |
| `fail_timeout` | 经历 `max_fails` 次失败后暂停服务的时间，单位秒，可与 `max_fails` 一起使用 |

## 4.5 OSI 七层模型与 TCP/IP 四层模型

**OSI 七层模型**

| 名称 | 解释 |
| --- | --- |
| 应用层 | 为应用程序提供服务 |
| 表示层 | 数据格式转化、数据加密 |
| 会话层 | 建立、管理和维护会话 |
| 传输层 | 建立、管理和维护端到端的连接 |
| 网络层 | IP 地址选址及路由选择 |
| 数据链路层 | 提供介质访问和链路管理 |
| 物理层 | 传输比特流（物理介质、电气特性） |

**TCP/IP 四层模型**

| 名称 | 解释 |
| --- | --- |
| 应用层 | FTP、SMTP、DNS、TFTP |
| 传输层 | TCP、UDP |
| 网络层 | ICMP、IP、ARP |
| 网络接口层 | 双绞线、无线网 |

> 补充：nginx 默认工作在**七层**（HTTP 协议层），依赖 `--with-stream` 编译后可通过 `stream {}` 块工作在**四层**（TCP/UDP）。

---

# 5. nginx 会话保持

负载均衡本身会让同一用户的请求落到不同后端，session 就会丢失。会话保持就是让同一客户端的请求始终回到同一台后端。

## 5.1 ip_hash

使用源地址哈希算法，把同一个客户端的请求总是发送给同一个后端服务器，除非该服务器不可用。

```nginx
upstream backend {
    ip_hash;
    server backend1.com;
    server backend2.com;
    server backend3.com down;
}
```

- **优点**：简单易用
- **缺点**：
  - 后端服务器宕机后，该机器上的 session 会话会丢失
  - 一直发送给同一台服务器，会导致负载不均衡

## 5.2 sticky_cookie_insert

让来自同一客户端的请求被传递到同一组服务器中的同一台。与 `ip_hash` 不同的是，它基于 **cookie** 而不是 IP 来判断客户端，因此可以缓解 `ip_hash` 负载不均衡的问题。

> 前提：该指令不是 nginx 内置功能，需要编译安装 **nginx-sticky-module** 模块后才能使用。

```nginx
upstream backend {
    server backend1.com;
    server backend2.com;
    sticky_cookie_insert  srv_id  expires=1h  domain=3evip.cn  path=/;
}

server {
    listen       80;
    server_name  3evip.cn;
    location / {
        proxy_pass  http://backend;
    }
}
```

| 参数 | 说明 |
| --- | --- |
| `expires` | 设置浏览器中保持 cookie 的时间 |
| `domain` | 定义 cookie 的域 |
| `path` | 定义 cookie 的路径 |

---

# 6. nginx 动静分离

为了加快网站的解析速度，把动态页面和静态页面交给不同的服务器解析，降低单个服务器的压力。实现方式是通过**正则表达式匹配**请求路径，再转发给不同的后端。

## 6.1 环境说明

| 角色 | IP |
| --- | --- |
| 代理服务器 | 192.168.229.136 |
| 静态网站 | 192.168.229.140 |
| 动态网站 | 192.168.229.150 |

## 6.2 三台机器都需要做

```bash
# 1、关闭防火墙与 selinux（见第 0 节）

# 2、配置 nginx 官方 yum 源 —— 建议 yum 安装
[root@admin ~]# vim /etc/yum.repos.d/nginx.repo
```

```ini
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
```

```bash
# 3、安装 nginx
[root@admin ~]# yum -y install nginx
```

## 6.3 代理服务器操作

```bash
# 1、修改配置文件
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
upstream jing {
    server 192.168.229.140:80 weight=1 max_fails=1 fail_timeout=60s;
}
upstream dong {
    server 192.168.229.150:80 weight=1 max_fails=1 fail_timeout=60s;
}

server {
    listen       80;
    server_name  localhost;

    # 静态资源
    location ~ .*\.(html|gif|jpg|png|bmp|css|js)$ {
        proxy_pass  http://jing;
        proxy_set_header  Host  $host:$server_port;
        proxy_set_header  X-Real-Ip  $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    }

    # 动态资源
    location ~ .*\.(php|jsp)$ {
        proxy_pass  http://dong;
        proxy_set_header  Host  $host:$server_port;
        proxy_set_header  X-Real-Ip  $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    }
}
```

```bash
# 2、检查配置文件语法
[root@admin ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

# 3、重启 nginx 服务，使配置生效
[root@admin ~]# systemctl restart nginx
```

## 6.4 静态服务器配置（192.168.229.140）

```bash
# 1、修改配置文件
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
server {
    listen       80;
    server_name  localhost;
    location ~ \.(html|gif|jpg|png|bmp|css|js) {
        root   /zx70;
        index  index.html index.htm;
    }
}
```

```bash
# 2、检查配置文件语法
[root@admin ~]# nginx -t

# 3、重启 nginx 服务
[root@admin ~]# systemctl restart nginx
```

## 6.5 动态服务器配置（192.168.229.150）

```bash
# 1、安装 php 相关软件
[root@admin ~]# rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
[root@admin ~]# rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
[root@admin ~]# yum -y install php71w-xsl php71w php71w-ldap php71w-cli php71w-common \
    php71w-devel php71w-gd php71w-pdo php71w-mysql php71w-mbstring php71w-bcmath php71w-mcrypt
[root@admin ~]# yum -y install php71w-fpm

# 2、启动 php 服务
[root@admin ~]# systemctl start php-fpm

# 3、修改 nginx 配置文件
[root@admin ~]# vim /etc/nginx/conf.d/default.conf
```

```nginx
server {
    listen       80;
    server_name  localhost;

    location ~ \.php$ {
        root           /dong;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}
```

```bash
# 4、检查配置文件语法格式
[root@admin ~]# nginx -t

# 5、重启服务生效
[root@admin ~]# systemctl restart nginx

# 6、创建网站文件
[root@admin ~]# mkdir /dong
[root@admin ~]# vim /dong/index.php
[root@admin ~]# cat /dong/index.php
hhahahaahhahahaahh
```

> 注：第 6 步只是验证 php-fpm 是否能被 nginx 调起。真正测试解析是否成功，`/dong/index.php` 里应写 `<?php phpinfo(); ?>`。

---

# 附录 A：勘误清单

本文档在原笔记基础上的修改，均为**拼写、语法、格式**类修正，未改动实验步骤与教学结论。

| 位置 | 原文 | 修正为 |
| --- | --- | --- |
| 全文 | `nignx` | `nginx` |
| 编译参数 | `--http-clent-body-temp-path` | `--http-client-body-temp-path` |
| 编译参数说明 | `--error-log-paht`、`--pid-paht` | `--error-log-path`、`--pid-path` |
| 查看模块 | `nginx -v` | `nginx -V`（`-v` 只显示版本号） |
| `--with-stream` 说明 | 支持 tcp 和 stp 代理 | 支持 tcp / udp 四层代理 |
| 1.6 配置文件 | `location = /50x.html {` 重复两行 | 删除重复行，修复括号层级 |
| 2.2 / 2.3 配置示例 | 同上，`location = /50x.html {` 重复 | 同上 |
| 3.5 代理配置 | `$proxy_add_x_forw` + `arded_for` 被断成两行 | `$proxy_add_x_forwarded_for` |
| 5.2 sticky 示例 | `sticky_cookie_indert` | `sticky_cookie_insert` |
| 5.2 sticky 示例 | 同时保留了 `ip_hash;` 与 sticky | 去掉 `ip_hash;`（两者冲突） |
| 5.2 sticky 示例 | `expires_1h` | `expires=1h` |
| OSI 表 | 传数层 | 传输层 |
| 四层模型表 | `FTP、SMTP、DNS TFIP`、`ICMP、IPARP` | `FTP、SMTP、DNS、TFTP`、`ICMP、IP、ARP` |
| 标题层级 | `#` / `##` / `###` / `####` 混用 | 统一为「章 `#` / 节 `##` / 小节 `###`」 |

另补充了原文标注"过程略"处的具体命令（关闭防火墙与 selinux）、域名虚拟主机的 hosts 解析提示、`.repo` 文件的语言标注，以及各代码块的语言类型（`bash` / `nginx` / `ini`），便于渲染和检索。
