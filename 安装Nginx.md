# Nginx 服务部署与基础配置

## 一、基本信息

- 课程名称：Linux 系统管理
- 授课章节：Nginx Web 服务部署与基础使用
- 授课对象：计算机应用 / 云计算专业学生
- 课时：2 课时（90 分钟）
- 授课环境：CentOS7 / CentOS Stream 9 / Ubuntu，关闭防火墙、SELinux 或放行 80 端口
- 前置知识：Linux 基础命令、yum/apt 软件包管理、端口、进程、HTTP 协议基础

## 二、教学目标

### 知识目标

1. 了解 Nginx 的特点、应用场景，对比 Apache 区别
2. 掌握 Nginx 安装、启动、自启、停止等服务管理操作
3. 理解 Nginx 主配置文件结构，熟悉 http、server、location 块作用
4. 掌握静态网站部署、虚拟主机配置

### 能力目标

1. 能够在 Linux 中独立安装 Nginx 并排查服务启动失败问题

2. 能够修改配置文件，部署静态网页

3. 能够配置基于域名的多虚拟主机，实现一台服务器多个网站

   ### Nginx 安装与服务管理（20 分钟）

   > 以 CentOS Stream9（yum/dnf）为例，附带 Ubuntu 命令

   #### 1. 软件源说明

   CentOS 默认源不带 nginx，需要官方 nginx 源或者 epel 源

   ```
   # CentOS安装epel源
   dnf install -y epel-release
   # 安装nginx
   dnf install -y nginx
   ```

   Ubuntu：

   ```
   apt update
   apt install -y nginx
   ```

   #### 2. Nginx 服务管理（systemd）

   ```
   # 查看服务状态
   systemctl status nginx
   # 启动服务
   systemctl start nginx
   # 设置开机自启
   systemctl enable nginx
   # 停止
   systemctl stop nginx
   # 重启（修改配置后常用）
   systemctl restart nginx
   # 重载配置（不中断服务，推荐！）
   systemctl reload nginx
   ```

   ✅ 重点区分：`restart` 是停止再启动；`reload` 平滑加载配置，业务不断开，生产优先用 reload。

   #### 3. 防火墙放行（CentOS）

   ```
   # 放行http 80端口
   firewall-cmd --add-service=http --permanent
   firewall-cmd --reload
   ```

   #### 4. 验证访问

   浏览器输入服务器 IP，出现 Nginx 默认欢迎页，代表部署成功。

   > 排查思路：访问不通 → 先看服务是否启动 → 防火墙 → 端口是否监听 `ss -tulnp | grep nginx`

   #### 5. Nginx 默认目录说明

   - 主配置文件：`/etc/nginx/nginx.conf`
   - 站点配置目录：`/etc/nginx/conf.d/`（推荐把站点配置放这里，方便管理）
   - 默认网页根目录：`/usr/share/nginx/html/`
   - 日志目录：`/var/log/nginx/`（access.log 访问日志，error.log 错误日志）

   ### （三）Nginx 主配置文件解析（25 分钟）

   打开 nginx.conf

   ```
   vim /etc/nginx/nginx.conf
   ```

   配置分为**全局块、events 块、http 块**，http 块里面包含 server 块（虚拟主机），server 里面包含 location 块。

   ```
   # 全局块：配置Nginx全局参数
   user nginx;                # 运行进程的用户
   worker_processes auto;     # 工作进程数量，auto等于CPU核心数
   error_log /var/log/nginx/error.log;
   pid /run/nginx.pid;
   
   # events块：网络连接相关
   events {
       worker_connections 1024; # 单个进程最大连接数
   }
   
   # http块：http服务核心配置，可以包含多个server
   http {
       include       /etc/nginx/mime.types; # 媒体类型映射
       default_type  application/octet-stream;
   
       log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';
   
       access_log  /var/log/nginx/access.log  main;
   
       sendfile        on;
       keepalive_timeout  65;
   
       # 引入conf.d目录下所有conf配置文件（重点！）
       include /etc/nginx/conf.d/*.conf;
   }
   ```

   > 设计规范：不要把所有站点写在 nginx.conf，新建 conf 放到 conf.d，便于维护。

   #### server 块（虚拟主机）示例

   新建文件 `/etc/nginx/conf.d/web1.conf`

   ```
   server {
       listen       80;                # 监听端口
       server_name  www.test1.com;     # 绑定域名
       root   /usr/share/nginx/html/web1; # 网站根目录
       index  index.html index.htm;    # 默认首页文件
   
       location / {
           try_files $uri $uri/ =404;
       }
   }
   ```

   - listen：监听端口
   - server_name：域名，实现一台服务器多个网站（虚拟主机）
   - root：网页存放目录
   - index：默认首页
   - location /：匹配所有请求路径

   #### ✅ 配置语法检查（非常重要）

   修改配置后，先检查语法，再重载

   ```
   nginx -t
   ```

   输出 `test is successful` 才代表配置没问题，否则根据报错修改。

   ### （四）实操任务 1：部署静态网站（15 分钟）

   任务：搭建一个简单静态网站

   1. 创建网站目录

   ```
   mkdir -p /usr/share/nginx/html/web1
   ```

   1. 编写首页 html

   ```
   echo "<h1>欢迎访问第一个Nginx网站 web1</h1>" > /usr/share/nginx/html/web1/index.html
   ```

   1. 编写 web1.conf 配置，如上
   2. 语法检查 `nginx -t`
   3. 重载配置 `systemctl reload nginx`
   4. 本地 hosts 解析测试（Windows：C:\Windows\System32\drivers\etc\hosts） 添加：`服务器IP  www.test1.com`
   5. 浏览器访问 [www.test1.com](https://www.test1.com) 验证

   ### （五）实操任务 2：基于域名的虚拟主机（10 分钟）

   一台 Nginx 同时跑两个网站 web1、web2

   1. 创建 web2 目录和首页

   ```
   mkdir -p /usr/share/nginx/html/web2
   echo "<h1>这是第二个网站 web2</h1>" > /usr/share/nginx/html/web2/index.html
   ```

   1. 新建 `/etc/nginx/conf.d/web2.conf`

   ```
   server {
       listen       80;
       server_name  www.test2.com;
       root   /usr/share/nginx/html/web2;
       index  index.html index.htm;
       location / {
           try_files $uri $uri/ =404;
       }
   }
   ```

   1. nginx -t 校验，reload
   2. hosts 添加：`服务器IP  www.test2.com`
   3. 分别访问两个域名，访问不同网站

   > 原理：Nginx 接收请求，读取请求头 Host 字段，匹配 server_name，分发到对应站点。