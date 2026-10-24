# 一、Shell函数

作用：Shell函数就是用于解决代码重用问题（让代码可以重复使用）

## 什么是函数？

Shell中允许将一组命令集合或语句形成一段可用代码，这些代码块称为Shell函数。给这段代码起个名字称为函数名，后续可以直接调用该段代码的功能。

## 函数的基本语法

```shell
函数名()
{
          函数体（一堆命令的集合，来实现某个功能）   
}

function 函数名()
{
           函数体（一堆命令的集合，来实现某个功能）  
}


function_name() {
        command
        command
}


function function_name() {
        command
        command
}
```

函数调用

```shell
函数名称
```

案例：

```shell
menu(){
        cat <<-EOF
            h	显示命令帮助
            f	显示磁盘分区
            d	显示磁盘挂载
            m	查看内存使用
            u	查看系统负载
            q	退出程序
            EOF

}
menu		//调用函数
```

小结：

函数有何作用？答：简化Shell脚本，让代码进行重用操作

注意：函数在定义时没有真正执行，只有在调用时才真正执行！

## 函数的return返回值

作用：让函数执行完毕后，返回一个结果给`<font style="color:rgb(51, 51, 51);">$?</font>`

基本语法：

```shell
# 定义函数
func() {
    return 0-256中的任意值
}
# 调用函数
func

return可以结束一个函数，类似于前面讲的循环控制语句break
return可以返回0-256中的任意一个值，当然0就代表成功，非0代表失败
如果没有return命令，函数将返回最后一个Shell的退出值
```

案例：

```shell
#!/bin/bash

# 定义一个函数，计算两个数字的除法
divide() {
    if [ $2 -eq 0 ]; then
        echo "错误：除数不能为0"
        return 1  # 如果除数为0，返回 1，表示错误
    else
        result=$(($1 / $2))  # 执行除法运算
        echo "结果: $result"
        return 0  # 返回 0，表示成功
    fi
}

# 调用函数，传入参数
divide 10 2
echo "函数返回值: $?"  # 0表示成功

divide 10 0
echo "函数返回值: $?"  # 1表示除数为0的错误
```

小结：

return可以结束一个函数，类似于前面讲的循环控制语句break(结束当前循环，执行循环体后面的代码)

return默认返回函数中最后一个命令的退出状态，也可以给定参数值，该参数值的范围是0-256之间。

如果没有return命令，函数将返回最后一个Shell的退出值。

## 案例：定期检查磁盘使用率并告警

某公司需要确保其生产环境中的服务器磁盘空间不会耗尽，以免影响系统的正常运行。运维团队希望使用 Shell 脚本定期检查服务器磁盘使用情况，当某个磁盘分区的使用率超过设定的阈值时，自动发出告警信息（例如通过发送邮件或日志记录），以便运维团队及时处理。

项目需求：

- 定期检查服务器上各个分区的磁盘使用情况。

- 设定一个使用率的阈值（如 80%），当某个分区的使用率超过此阈值时发出告警。

- 在告警时记录日志，并发送邮件给运维团队，提醒需要清理磁盘。

- 使用 Shell 函数实现各项功能，包括检查磁盘、记录日志和发送告警。check_disk_usage()、alert_disk_usage()



解决方案：使用 Shell 函数进行磁盘检查和告警

Shell 脚本思路：

1. 编写一个 Shell 函数来检查所有分区的磁盘使用率。

1. 编写另一个函数来记录告警信息并发送邮件通知。

1. 将这个脚本设为定时任务，通过 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">crontab</font>` 每隔一段时间执行。

提前安装sendmail邮件服务

```shell
yum -y install sendmail
systemctl start sendmail
systemctl enable sendmail
```

注意：如果电脑中安装了sendmail，也按照老师代码编写，但是还是无法发送邮件，本质问题在于你的主机名称不符合FQDN规范。

```shell
FQDN = 功能 + 公司域名
mysql.lhp.cn
web.lhp.cn

node1.lhp.cn
node2.lhp.cn
```

修改主机名称

```shell
hostnamectl set-hostname node1.lhp.cn
su
```

编写脚本

```shell
#!/bin/bash

# 定义告警日志文件和使用率阈值
LOGFILE="/var/log/disk_usage.log"
# 测试阈值可以小一些，生产建议80-85
THRESHOLD=5

# 定义告警邮箱
ALERT_EMAIL="15201008359@163.com"
FROM_EMAIL="centos9@server.com"

# 检查磁盘使用率的函数
check_disk_usage() {
    # 使用 df 命令获取每个分区的使用率
    df -h | grep '^/dev/' | while read line; do
        # 提取磁盘分区和使用率
        PARTITION=$(echo $line | cut -d' ' -f1)
        USAGE=$(echo $line | cut -d' ' -f5 | tr -d '%')
        

        # 如果使用率超过设定的阈值，调用告警函数
        if [ $USAGE -ge $THRESHOLD ]; then
            alert_disk_usage $PARTITION $USAGE
        fi
    done
}

# 告警函数，记录日志并发送邮件
alert_disk_usage() {
    PARTITION=$1
    USAGE=$2
    SUBJECT="磁盘使用率告警: $PARTITION 达到 $USAGE%"

    # 记录告警日志
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告: 分区 $PARTITION 使用率已达到 $USAGE%" >> $LOGFILE

    # 发送告警邮件
    {
        echo "To: $ALERT_EMAIL"
        echo "From: $FROM_EMAIL"
        echo "Subject: $SUBJECT"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo "Content-Transfer-Encoding: 8bit"
        echo ""
        echo "警告："
        echo "服务器上的分区 $PARTITION 使用率已达到 $USAGE%。请尽快检查并清理磁盘，避免服务中断。"
    } | sendmail -t
}

# 调用检查磁盘使用率的函数
check_disk_usage

注：read在读取磁盘信息时，会自动去除多余的空格
```

扩展：软链接、硬链接，链接顾名思义就是给源文件做了一个链接（快捷方式）

软链接：在实际工作中，使用最多的叫软链接（快捷方式）

链接：link

```shell
ln -s  源文件的路径 链接路径
```

注意事项：链接路径，还是源文件路径必须是绝对路径方式

举个栗子：

```shell
ln -s /etc/nginx/conf.d/wordpress.conf /root/wordpress.conf
ll /root
软链接特点：
① 有颜色的，浅蓝色
② 软链接一般会有 -> 箭头指向
③ 查看权限时，第1列代表文件类型，如果是软链接则类型为l（小写的L）
```

作用：简化软件访问或文件访问路径（可以是文件也可以是文件夹）

区别：删除源文件，则软链接就无法访问了（失效了）



硬链接：在实际工作中，使用较少，主要用于数据备份、版本控制等功能（理解又复制了一个文件，删除源文件，对硬链接没有任何影响）

作用：实现数据备份

基本语法：

```shell
ln   源文件路径  硬链接路径
注意：没有选项，没有-s
```

举个栗子：

```shell
ln /var/log/disk_usage.log /root/disk_usage.log
ls
查看后发现，硬链接文件也是白色的，没有任何颜色的变化
ll
查看后发现，硬链接文件没有箭头指向，文件类型也是普通文件-
从外观和表现上来看，硬链接文件与源文件几乎没有区别
注意：硬链接不同于软链接，硬链接有点类似把文件复制一份，删除源文件对硬链接没有任何影响。
实际工作中，硬链接可以使用文件共享，也可以实现数据备份。
```



inode（索引节点值）：文件指针，在Linux操作系统中，文件有两部分内容组成：元数据（文件名称、元数据结构、文件属性） + 实际数据，inode文件指针，不存储实际数据，只是元数据指针 => 在Linux系统中可以通过`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">ls -i</font>`来进行查看文件的inode值。

```shell
硬链接文件，源文件与链接文件inode值相同的 => 元数据相同
软链接文件，源文件与链接文件inode值不同的 => 元数据不同，删除源文件，查看链接时，软链接内容已经不见了
```

# 二、Shell正则表达式

作用：在Linux操作系统中，Shell正则表达式可以用于复杂数据处理（检索、替换、删除）。

## 正则表达式

正则表达式(regular expression)描述了一种**字符串**匹配的模式，可以用来检查一个串是否含有某种子串、将匹配的子串做替换或者从某个串中取出符合某个条件的子串等。 

注意：正则表达式是一个独立的语言，不仅可以在Shell脚本中使用，在Python中也可以使用

Shell：数据检索、数据处理

Python：数据检索、爬虫技术

## 应用场景

① 数据验证（表单验证、如手机、邮箱、IP地址）

② 数据检索（数据检索、数据抓取）

③ 数据过滤（敏感词过滤）=> 论坛、小说

…

## 正则表达式详解

普通匹配

```shell
#!/bin/bash

# 提取 CPU 型号
grep "model name" /proc/cpuinfo | uniq

# 提取 CPU 核心数
grep "cpu cores" /proc/cpuinfo | uniq
```

grep选项-E 和 -P区别：

普通用法：`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">grep 关键词 字符串</font>`

正则用法：

```
<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">grep -E 正则表达式 字符串</font>
<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">grep -P 正则表达式 字符串</font>
```



`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">-E</font>` (Extended Regular Expressions, 扩展正则表达式)

```shell
扩展正则表达式
-E选项启用了 扩展正则表达式（ERE），它比标准的基本正则表达式（BRE）支持更多的功能，例如：
使用 +（表示一个或多个）、?（表示零个或一个）、|（表示或）等元字符时，不需要加反斜杠（\）进行转义。
支持括号 () 和竖线 | 等用于分组和选择的功能。
```



`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">-P</font>`选项启用了 Perl 兼容正则表达式（PCRE），它支持更强大、更复杂的正则表达式功能，包括一些扩展的功能，例如：

```shell
支持一些在 -E 中不支持的功能，例如 \d，\w，\b（单词边界）等
正则表达式的语法更接近 Perl
```



正则工具箱：https://goldtools.cn/regexp

正则匹配三步走：① 查什么 ② 查多少 ③ 从哪查

### 查什么（元字符）

| **代码**    | **功能**                                                     |
| ----------- | ------------------------------------------------------------ |
| .           | 匹配任意1个字符（除了\n）                                    |
| [ ]         | 匹配[ ]中列举的字符，字符簇，本身表示一个范围区间，每次只能匹配其中的某个字符 |
| [^指定字符] | 匹配除了指定字符以外的所有字符，^托字节在字符簇中出现代表取反的意思 |
| \d          | 匹配数字，即0-9，\d都称之为Perl风格语法                      |
| \D          | 匹配非数字，即不是数字                                       |
| \s          | 匹配空白，即 空格，tab键                                     |
| \S          | 匹配非空白                                                   |
| \w          | 匹配非特殊字符，即a-z、A-Z、0-9、_                           |
| \W          | 匹配特殊字符，即非字母、非数字                               |

[a-z]匹配26个小写字符中的任意一个，[A-Z]匹配26个大写字符中的任意一个，[0-9]任意一个数字，[3-9]匹配3-9之间的任意一个数字，[aeiou]匹配小aeiou五个字符中的任意一个

[a-z] ：匹配除了26个小写字母以外的任意字符，[0-9] ：匹配除数字以外的任意字符

案例1：查找包含小写字母的行

```shell
grep "[a-z]" file.txt
```

案例2：匹配包含ERROR关键字的行

```shell
grep ERROR /var/log/mysqld.log
```

案例3：查找当前目录中包含数字的文件名

```shell
#!/bin/bash

# 查找包含数字的文件名
ls | grep -E "[0-9]"
```

小结：

在实际工作中，元字符主要用于匹配我们想要的字符。

### 查多少（匹配符）

| **代码** | **功能**                                                     |
| -------- | ------------------------------------------------------------ |
| *        | 匹配前一个字符出现0次或者无限次，即可有可无，简称0到多       |
| +        | 匹配前一个字符出现1次或者无限次，即至少有1次，简称1到多      |
| ?        | 匹配前一个字符出现1次或者0次，即要么有1次，要么没有，简称0或1 |
| {m}      | 匹配前一个字符出现m次，{3}，匹配前一个字符只能出现3次        |
| {m,}     | 匹配前一个字符至少出现m次，{3,}，匹配前一个字符至少出现3次，相当于3到多 |
| {m,n}    | 匹配前一个字符出现从m到n次，{3,5}，匹配前一个字符至少出现3次，至多出现5次 |

案例1：从日志文件中提取所有包含 IP 地址的行。IP 地址是数字和点号的组合，类似 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">192.168.0.1</font>`

access.log

LNMP => Nginx => PHP（故障） => 500

LNMT => Nginx => Tomcat（故障）=> 500

```shell
192.168.1.1 - - [07/Jan/2025:12:45:32 +0000] "GET /index.html HTTP/1.1" 200 1024
172.16.0.2 - - [07/Jan/2025:12:46:15 +0000] "POST /login HTTP/1.1" 403 2048
192.168.2.3 - - [07/Jan/2025:12:47:22 +0000] "GET /about.html HTTP/1.1" 200 1024
10.0.0.4 - - [07/Jan/2025:12:48:44 +0000] "GET /contact.html HTTP/1.1" 404 512
invalid_ip - - [07/Jan/2025:12:49:55 +0000] "GET /invalid HTTP/1.1" 400 0
#!/bin/bash

# 定义日志文件
LOGFILE="/var/log/access.log"

# 使用正则表达式提取包含IP地址的行
grep -P "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" $LOGFILE
```

案例2：查找日志文件中日期格式为 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">YYYY-MM-DD</font>` 的记录，确保年份部分有 4 位数字，日期部分格式正确。

application.log

```shell
2025-01-01 应用启动
2025-01-02 用户登录
Error: 无法连接数据库
2025-01-03 数据导入成功
系统错误发生在2025-01-04
用户退出
#!/bin/bash

# 定义日志文件
LOGFILE="/var/log/application.log"

# 匹配日期格式 YYYY-MM-DD
grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" $LOGFILE
```

案例3：提取邮件地址

file_with_emails.txt

```shell
valid.email@example.com
another.email@domain.org
invalid-email.com
yet.another.email@sub.domain.co.uk
123@numbers.com
missingatsign.com
email@valid-domain.com
not_a_valid_email@com
#!/bin/bash

# 定义包含邮件地址的文件
EMAIL_FILE="file_with_emails.txt"

# 提取邮件地址并输出
grep -E "[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" $EMAIL_FILE
```

注意：如果`<font style="background-color:rgb(243, 244, 244);">.</font>`点号出现在`<font style="background-color:rgb(243, 244, 244);">[]</font>`字符簇中，则不需要\反斜杠转义，就代表点号普通字符。

注意：如果在[]字符簇同时出现了点号、下划线以及横岗，则点号必须在前，如._-，否则会有语法错误

案例4：从库存文件中提取所有符合产品编号格式（如 "P12345"、"A7890"）的记录

stock.txt

```shell
A123 产品A
B4567 产品B
C890 产品C
D12 产品D
XYZ123 产品E
A 1234 产品F
#!/bin/bash

# 定义库存文件路径
STOCKFILE="/data/stock.txt"

# 提取产品编号
grep -P "\b[A-Z][0-9]+\b" $STOCKFILE
```

\b：代表边界，以上就是就代表字符必须和数字连在一起，两边可以有空格但是中间必须连续

小结：

匹配符就是用于匹配前面一个字符出现多少次！！！

### 从哪查（定位符）

| **代码** | **功能**                                          |
| -------- | ------------------------------------------------- |
| ^        | 托字节，匹配字符串开头，^/dev：匹配以/dev开头的行 |
| $        | 匹配字符串结尾                                    |

案例1：检查 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">/etc/passwd</font>` 文件中是否有用户账户的名称以特定字符（如 "admin"）开头

```shell
#!/bin/bash

# 检查 /etc/passwd 中以 "admin" 开头的账号
grep -E '^admin.*' /etc/passwd
```

案例2：去除配置文件中的注释以及空行

```shell
#!/bin/bash

# 定义配置文件
CONFIG_FILE="/etc/my.cnf"

# 查找包含前导空格或尾随空格的行
egrep -v '^#|^$' $CONFIG_FILE
```

## 分组、捕获、反向引用

作用：主要是进行重复数据的匹配操作

举个栗子：1234-1111-1221-3333

要求：要求使用正则匹配1111以及3333这种格式的数字

要求：要求使用正则匹配1221这种格式的数字

### 分组

在正则表达式中，通过一对圆括号括起来的内容，我们就称之为"分组"。

\d(\d)(\d)

正则表达式中`<font style="color:rgb(51, 51, 51);">\d(\d)(\d)</font>`中，`<font style="color:rgb(51, 51, 51);">(\d)(\d)</font>`就是子表达式，一共有两个`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">()</font>`圆括号，则代表两个分组

### 捕获

当正则表达式在字符串中匹配到相应的内容后，计算机系统会自动把分组所匹配的到内容放入到系统的对应缓存区中（缓存区从1开始）

### 反向引用

在正则表达式中，我们可以通过\n（n代表第n个缓存区的编号）来引用缓存区中的内容，我们把这个过程就称之为"反向引用"。



案例1：

① 查找连续的四个数字，如：3569

```shell
答：[0-9]{4}或\d{4}
```

② 查找连续的相同的四个数字，如：1111

```shell
答：(\d)\1\1\1
```

③ 查找数字，如：1221,3443

```shell
答：(\d)(\d)\2\1
```

④ 查找字符，如：AABB,TTMM（提示：A-Z，正则：[A-Z]）

```shell
答：([A-Z])\1([A-Z])\2
```

⑤ 查找连续相同的四个数字或四个字符（提示：\w）

```shell
答：(\w)\1{3}
```

**注：以上都是Perl风格写法，grep必须配合-P使用**

小结：

作用：主要是进行重复数据的匹配操作

有几个小括号就有几个分组，执行顺序都是从左向右 => （\d)(\d)

## Shell正则案例

案例1：从日志中提取特定 IP 地址

场景：在 Web 服务器日志中定位所有来自特定 IP 地址（如 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">192.168.1.10</font>`）的请求，以分析某个用户的访问情况。

```shell
access.log
192.168.1.10 - - [07/Jan/2025:12:45:32 +0000] "GET /index.html HTTP/1.1" 200 1024
172.16.0.2 - - [07/Jan/2025:12:46:15 +0000] "POST /login HTTP/1.1" 403 2048
192.168.2.3 - - [07/Jan/2025:12:47:22 +0000] "GET /about.html HTTP/1.1" 200 1024
10.0.0.4 - - [07/Jan/2025:12:48:44 +0000] "GET /contact.html HTTP/1.1" 404 512
invalid_ip - - [07/Jan/2025:12:49:55 +0000] "GET /invalid HTTP/1.1" 400 0


grep '^192\.168\.1\.10' access.log

查找所有以 192.168.1.10 开头的行（即来自该 IP 的请求），^ 表示行首匹配，\. 用于匹配点字符。
```

案例2：提取磁盘使用率超过 80% 的分区

场景：监控磁盘空间，提取所有磁盘使用率超过 80% 的分区，并及时提醒管理员。

```shell
df -h | awk '$5 ~ /[8-9][0-9]%|100%/ {print $0}'

df -h：显示各分区磁盘使用情况，以人类可读的格式输出。
awk '$5 ~ /[8-9][0-9]%|100%/ {print $0}'：使用 awk 对使用率（第五列）匹配正则表达式 [8-9][0-9]%|100%，提取所有使用率超过 80% 的分区。

$5获取第5列
/[8-9][0-9]%|100%/ ：数字第1位必须是8或9，第2位0-9之间的任一数字 => 80% ~ 99%  |或 100%
{print $0}，把满足正则的这一行提取出来
```

案例3：提取特定日期的 SSH 登录尝试

场景：查找系统中在特定日期（如 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">1月8号</font>`）的 SSH 登录尝试，以检查是否有异常登录行为。

```shell
grep "Jan   8" /var/log/secure | grep "sshd"
```

案例4：筛选出错误日志中的 URL

场景：在 Web 服务器的错误日志中提取所有访问失败的 URL，用于分析哪些页面访问出现错误频率较高。

```shell
error.log
127.0.0.1 - - [09/Jan/2025:10:00:01 +0000] "GET /page1.html HTTP/1.1" 404 512
192.168.0.1 - - [09/Jan/2025:10:00:02 +0000] "POST /api/v1/login HTTP/1.1" 200 1024
10.0.0.1 - - [09/Jan/2025:10:00:03 +0000] "GET /page2.html HTTP/1.1" 404 128
127.0.0.1 - - [09/Jan/2025:10:00:04 +0000] "GET /page3.html HTTP/1.1" 404 256
10.0.0.2 - - [09/Jan/2025:10:00:05 +0000] "GET /index.html HTTP/1.1" 200 2048
192.168.0.2 - - [09/Jan/2025:10:00:06 +0000] "GET /page1.html HTTP/1.1" 404 512
127.0.0.1 - - [09/Jan/2025:10:00:07 +0000] "GET /favicon.ico HTTP/1.1" 404 64
192.168.0.3 - - [09/Jan/2025:10:00:08 +0000] "GET /robots.txt HTTP/1.1" 404 32
10.0.0.1 - - [09/Jan/2025:10:00:09 +0000] "POST /api/v1/logout HTTP/1.1" 200 512
192.168.0.1 - - [09/Jan/2025:10:00:10 +0000] "GET /page1.html HTTP/1.1" 404 512

grep "404" error.log | awk '{print $7}' | sort | uniq -c | sort -nr
```

# 三、expect

`<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">expect</font>` 是一个用于自动化交互的工具，通常用于自动化 SSH 登录、安装脚本、密码输入等需要用户交互的任务。以下是 `<font style="color:rgb(51, 51, 51);background-color:rgb(243, 244, 244);">expect</font>` 的基础教程，包含基本概念、安装和常见用法。

作用：解决大部分脚本需要用户交互的场景，通过expect让脚本变成完全自动化形式！

## expect工具安装

安装expect

```shell
# CentOS/RHEL
sudo dnf install expect -y
```

expect 脚本一般包含以下几个基本元素：

- **spawn**：用于启动需要自动化的命令或程序。

- **expect**：定义程序期望看到的输出，expect 会等待输出内容符合条件时再进行下一步。

- **send**：向程序发送字符串，如输入命令或确认。

- **interact**：允许用户和脚本的交互，通常在脚本末尾使用，以保持会话打开。

## expect脚本结构

```shell
#!/usr/bin/expect
# 设置变量
set timeout 10
set password "123456"

# 启动命令
spawn ssh root@192.168.88.102

# 匹配期望的输出
expect {
  "yes/no" {
    send "yes\r"
    exp_continue
  }
  "password:" {
    send "$password\r"
  }
}

# 保持会话交互
interact


以上内容解析：
#!/usr/bin/expect：指定脚本解释器。
set：用于设置变量，timeout 指定超时时间，超过时间后 expect 将退出。
spawn：启动一个命令，比如 ssh。
expect：等待命令的输出符合指定模式，类似于 “等待提示”。
send：向命令发送输入，$password\r 表示发送密码，并按下回车。
interact：保持交互模式，让用户可以手动操作（通常用于保持会话）。
```



```shell
#!/usr/bin/expect
# 开启一个程序
spawn ssh root@192.168.88.102

# 捕获相关内容
expect {
    # 处理主机指纹确认
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    # 处理密码输入
    "password:" {
        send "123456\r"
    }
}

# 交互模式
interact
```

执行expect脚本：

```shell
# expect xxx.sh
```

## 举例说明

**需求1：**A远程登录到server上什么都不做

```shell
#!/usr/bin/expect
# 开启一个程序
spawn ssh root@192.168.88.102
# 捕获相关内容
expect {
    "Are you sure you want to continue connecting" {
        send "yes\r"
        exp_continue
    }
    "password:" {
        send "123456\r"
    }
}
interact

脚本执行方式：
# ./expect1.sh
# /shell03/expect1.sh
# expect -f expect1.sh

1）定义变量
#!/usr/bin/expect
set ip 192.168.88.102
set pass 123456
set timeout 5
spawn ssh root@$ip
expect {
    "yes/no" { send "yes\r";exp_continue }
    "password:" { send "$pass\r" }
}
interact


2）使用位置参数
#!/usr/bin/expect
set ip [ lindex $argv 0 ]
set pass [ lindex $argv 1 ]
set timeout 5
spawn ssh root@$ip
expect {
    "yes/no" { send "yes\r";exp_continue }
    "password:" { send "$pass\r" }
}
interact

[ lindex $argv 0 ]获取从外部传递的第一个参数  lindex 第一个字母是小写的L
[ lindex $argv 1 ]获取从外部传递的第二个参数
```

interact代表保持会话，简单理解就是暂停，等待用户交互（等待用户输入）

**需求2：**A远程登录到server上操作

```shell
#!/usr/bin/expect
set ip 192.168.88.102
set pass 123456
set timeout 5
spawn ssh root@$ip
expect {
    "yes/no" { send "yes\r";exp_continue }
    "password:" { send "$pass\r" }
}

expect "#"
send "rm -rf /tmp/*\r"
send "touch /tmp/file{1..3}\r"
send "date\r"
send "exit\r"
expect eof
```

expect eof：等待expect脚本执行结束，释放expect占用的系统资源

**需求3：**shell脚本和expect结合使用，在多台服务器上创建1个用户

```shell
# cat ip.txt 
192.168.88.101 123456
192.168.88.102 123456


1. 循环
2. 登录远程主机——>ssh——>从ip.txt文件里获取IP和密码分别赋值给两个变量
3. 使用expect程序来解决交互问题

#!/bin/bash
# 循环在指定的服务器上创建用户和文件
while read ip pass
do
    /usr/bin/expect <<-END &>/dev/null
    spawn ssh root@$ip
    expect {
    "yes/no" { send "yes\r";exp_continue }
    "password:" { send "$pass\r" }
    }
    expect "#" { send "useradd yy1;rm -rf /tmp/*;exit\r" }
    expect eof
END
done < ip.txt

#!/bin/bash
cat ip.txt|while read ip pass
do
        {

        /usr/bin/expect <<-EOF
        spawn ssh root@$ip
        expect {
                "yes/no" { send "yes\r";exp_continue }
                "password:" { send "$pass\r" }
        }
        expect "#"
        send "hostname\r"
        send "exit\r"
        expect eof
EOF

        }&
done
wait
echo "user is ok...."


或者
#!/bin/bash
while read ip pass
do
        {

        /usr/bin/expect <<-EOF
        spawn ssh root@$ip
        expect {
                "yes/no" { send "yes\r";exp_continue }
                "password:" { send "$pass\r" }
        }
        expect "#"
        send "hostname\r"
        send "exit\r"
        expect eof
EOF

        }&
done<ip.txt
wait
echo "user is ok...."
```