第一部分 测试环境

一、 简要信息
节点机：
操作系统： 版本 CentOS 7.2.1511 内核 3.10.0-327.36.2.el7.x86_64
IP: 10.10.0.1
10.10.0.2
10.10.0.3
10.10.0.4
10.10.0.5
10.10.0.6
管理机：
操作系统： 版本 Ubuntu 16.04.1 LTS 内核 4.4.0-42-generic

二、 环境准备
1、节点机关闭selinux。打开selinux配置文件：
$ sudo vim /etc/selinux/config
将SELINUX设为disabled
2、关闭防火墙。
$ sudo systemctl stop firewalld
$ sudo systemctl disable firewalld

第二部分 redis cluster介绍

redis3.0 提供cluster的功能，使用redis-trib.rb工具构建Redis Cluster。Redis Cluster采用无中心结构，每个节点保存数据和整个集群状态, 每个节点都和其他所有节点连接。节点之间使用gossip协议传播信息以及发现新节点。Redis集群中节点不作为client请求的代理，client根据node返回的错误信息重定向请求。

一、基本架构
 无中心自组织的结构
 各节点维护Key->Server的映射关系
 Client可以向任意节点发起请求，节点不会转发请求，只是重定向Client
 如果在Client第一次请求和重定向请求之间，Cluster拓扑发生改变，则第二次重定向请求将被再次重定向，直到找到正确的Server为止

数据分片算法：Key空间被划分为16384个区间,每个Master节点负责一部分区间。

二、水平扩容
 支持通过运行时增加Master节点来水平扩容，提升存储容量，尽力降低命中率波动
 存在节点A，需要迁出其中的部分Key区间。新增节点B，接收由节点A迁出的Key区间。
 相应Key区间的请求首先还是会发送给A节点：如果请求为新建Key则直接重定向到B节点；如果请求不是新建Key且A节点存储有对应的Key则直接作出响应，否则重定向到B节点
 同时Cluster会调用实用工具redis-trib向A节点发送MIGRATE命令，把迁移区间内的所有Key原子的迁移到B节点：同时锁住A、B节点=》在A节点删除Key=》在B节点新建Key=》解锁
 运行时动态迁移大尺寸键值可能造成响应时延

三、主从备份没有主从备份的节点一旦故障，将导致整个集群失败：无法写入/读取任何Key；无法进行数据重新分片。

四、 架构图


五、功能限制
 当Client连接到集群的主体部分时可能有少量的写丢失，当Client连接到集群的小部分时可能有显著的写丢失
 复杂的多Key操作（Set求并/求交）不能跨节点操作,可以通过使用Hash Tag使相关Key强制哈希到同一Server，但是在数据重新分片期间，还是可能有时间不可用
 不支持MULTI/EXEC

第三部分 redis cluster实践

一、节点机安装和配置redis
下载安装包并安装
$ wget ftp://195.220.108.108/linux/remi/enterprise/7/remi/x86_64/redis-3.2.4-1.el7.remi.x86_64.rpm
$ sudo rpm -ivh redis-3.2.4-1.el7.remi.x86_64.rpm
打开配置文件。
$ sudo vim /etc/redis.conf
修改下列配置项。
port 6379
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 15000
appendonly yes

启动并设置成开机启动。
$ sudo systemctl start redis
$ sudo systemctl enable redis

查看启动情况。
$ sudo systemctl is-active redis
active
$ redis-cli ping
PONG
说明启动成功。
如果没有成功，可以到/var/log/redis/redis.log查看日志。

二、管理机安装redis-trib.rb
下载redis-trib.rb
$ wget https://raw.githubusercontent...
$ sudo cp redis-trib.rb /usr/local/bin/redis-trib.rb
$ sudo chmod 755 /usr/local/bin/redis-trib.rb
$ sudo apt install ruby ruby-redis

三、将节点构建成集群
使用redis自带的redis-trib.rb工具实现集群创建、节点添加/删除、重新划分等功能。
在管理机执行命令，构建集群：
$ redis-trib.rb create --replicas 1 10.10.0.1:6379 10.10.0.2:6379 10.10.0.3:6379 10.10.0.4:6379 10.10.0.5:6379 10.10.0.6:6379
命令执行完毕，如果显示：
[OK] All 16384 slots covered.
则说明集群构建成功。

四、测试集群
使用redis-cli登陆任何一个节点，进行保存、删除、获取等操作。
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> set a 100
-> Redirected to slot [15495] located at 10.10.0.3:6379
OK
10.10.0.1:6379> get a
"100"
10.10.0.1:6379> set b mmm
-> Redirected to slot [3300] located at 10.10.0.1:6379
OK
10.10.0.1:6379> get b
"mmm"
10.10.0.1:6379> quit

五、重新分配哈希槽
使用redis-cli登陆任何一个节点，查看当前节点信息，包括节点ID、节点上哈希槽数目、主从等信息。
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> cluster nodes
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472613177176 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472613175661 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472613175158 2 connected 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472613177176 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 0-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472613176670 5 connected

命令格式：redis-trib.rb reshard --from <node-id> --to <node-id> --slots <number of slots> --yes <host>:<port>

在管理机执行命令:
$ redis-trib.rb reshard --from f3ee1b205b449b7ef751a31507173a8b3811e061 --to 23a9df9ac74be3d613d1e75eef47337e84447750 --slots 100 --yes 10.10.0.1:6379
表示由节点10.10.0.1上移动100个哈希槽到节点10.10.0.2上。

命令执行完成，再次查看：
10.10.0.1:6379> cluster nodes
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472613338926 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472613337916 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472613338020 7 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472613338623 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472613339929 7 connected

注意节点10.10.0.1和10.10.0.2上哈希槽数目变化，说明移动成功。

六、添加新的节点
1、添加新的主节点
先查看现有集群的节点情况：
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> cluster nodes
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472613338926 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472613337916 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472613338020 7 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472613338623 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472613339929 7 connected

在管理机执行命令:
$ redis-trib.rb add-node 10.10.0.7:6379 10.10.0.1:6379
表示将节点10.10.0.7添加到节点10.10.0.1所在的集群。
出现如下信息说明命令执行成功：
[OK] New node added correctly.

再次查看集群节点情况：
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472614557239 0 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472614557239 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472614558254 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472614557741 7 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472614559265 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472614558764 7 connected

10.10.0.7已经作为主节点在集群中了。给新加入的主节点分配哈希槽，就可以使用了。

2、添加新的从节点
先查看现有集群的节点情况：
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472614557239 0 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472614557239 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472614558254 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472614557741 7 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472614559265 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472614558764 7 connected

在管理机执行命令:
$ redis-trib.rb add-node --slave --master-id c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.8:6379 10.10.0.1:6379
表示将节点10.10.0.8添加到节点10.10.0.1所在的集群，并且指定主节点为10.10.0.7。
出现如下信息说明命令执行成功：
[OK] New node added correctly.

再次查看集群节点情况：
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472620265061 0 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472620264551 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472620265061 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472620266065 7 connected 0-99 5461-10922
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 slave c0217425f82b58b897a677621d22d42c68ce9072 0 1472620266266 8 connected
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472620265563 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472620264049 7 connected

10.10.0.8已经作为从节点在集群中了，并且主节点是10.10.0.7。

七、删除集群中已有的节点
1、删除从节点
先查看现有集群的节点情况：
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472620265061 0 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472620264551 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472620265061 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472620266065 7 connected 0-99 5461-10922
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 slave c0217425f82b58b897a677621d22d42c68ce9072 0 1472620266266 8 connected
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472620265563 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
00ee58ae2ff19dca866d3bbfd7076b61f7eb1761 10.10.0.5:6379 slave 23a9df9ac74be3d613d1e75eef47337e84447750 0 1472620264049 7 connected

在管理机执行命令:
$ redis-trib.rb del-node 10.10.0.1:6379 00ee58ae2ff19dca866d3bbfd7076b61f7eb1761
表示将节点10.10.0.5由节点10.10.0.1所在的集群中删除。
出现如下信息说明命令执行成功：
SHUTDOWN the node.

再次查看集群节点情况：
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472621229736 0 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472621229224 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472621230753 4 connected
23a9df9ac74be3d613d1e75eef47337e84447750 10.10.0.2:6379 master - 0 1472621231255 7 connected 0-99 5461-10922
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 slave c0217425f82b58b897a677621d22d42c68ce9072 0 1472621230753 8 connected
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472621230240 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460

10.10.0.5已经从集群中删除了。

2、删除主节点
欲删除的主节点必须是空的。否则删除时会报错：
[ERR] Node 10.10.0.2:6379 is not empty! Reshard data away and try again.
必须先将欲删除的主节点的哈希槽转移给其他的主节点，以清空该主节点。
然后就可以删除了。操作方法和删除从节点一样。不赘述。

八、查看集群状态
在管理机执行命令:
$ redis-trib.rb check 10.10.0.1:6379
表示查看节点10.10.0.1所在的集群的状态。
出现如下信息说明集群正常：
[OK] All 16384 slots covered.

九、获取集群信息
在管理机执行命令:
$ redis-trib.rb info 10.10.0.1:6379
表示获取节点10.10.0.1所在的集群的信息。
出现如下信息说明执行成功：
[OK] 7 keys in 3 masters.
执行成功会列出集群主节点，每个主节点保存的键个数和所拥有的从节点。

十、节点不可用测试
先查看现有集群的节点情况：
$ redis-cli -c -h 10.10.0.1 -p 6379
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master - 0 1472621978887 9 connected 0-99 5461-10922
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472621980916 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472621979893 4 connected
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 slave c0217425f82b58b897a677621d22d42c68ce9072 0 1472621980404 9 connected
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472621980916 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460

将10.10.0.7关机，再次查看集群节点情况：
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master,fail - 1472624375231 1472624373622 9 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472624406864 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472624405845 4 connected
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 master - 0 1472624406864 10 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472624405342 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460
可知节点10.10.0.7已经不可用。原来10.10.0.7的从节点10.10.0.8自动变成主节点，并将10.10.0.7上的哈希槽复制过来。

再将10.10.0.8关机，再次查看集群节点情况：
10.10.0.1:6379> cluster nodes
c0217425f82b58b897a677621d22d42c68ce9072 10.10.0.7:6379 master,fail - 1472624375231 1472624373622 9 connected
3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 10.10.0.3:6379 master - 0 1472624861850 3 connected 10923-16383
41d77bba738c1b00ff35f8b1d9757137f7c3ef62 10.10.0.4:6379 slave f3ee1b205b449b7ef751a31507173a8b3811e061 0 1472624862855 4 connected
4dd86339b87818fa8deafc5aabd0c46b4c8603c6 10.10.0.8:6379 master,fail - 1472624827957 1472624827656 10 connected 0-99 5461-10922
012d2e589794478fa87e15fecccaae39523c5f1c 10.10.0.6:6379 slave 3fdf4f00afc66aa254915c3c9aff30c7d1c89f87 0 1472624861348 6 connected
f3ee1b205b449b7ef751a31507173a8b3811e061 10.10.0.1:6379 myself,master - 0 0 1 connected 100-5460

可知节点10.10.0.8已经不可用。此时整个集群不可用。
10.10.0.1:6379> cluster info
cluster_state:fail
cluster_slots_assigned:16384
cluster_slots_ok:10822
cluster_slots_pfail:0
cluster_slots_fail:5562
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:10
cluster_my_epoch:1
cluster_stats_messages_sent:59550
cluster_stats_messages_received:59389

需要重新构建集群。即：集群中的片的所有节点不能同时不可用，否则整个集群不可用。

十一、客户端
Ruby客户端： https://github.com/antirez/re...
Python客户端：https://github.com/Grokzen/re...

第三部分 参考资料

一、redis官方指南：
http://redis.io/topics/cluste...
http://ifeve.com/redis-cluste...
二、redis集群方案比较：
http://chong-zh.iteye.com/blo...
http://h2ex.com/1130
http://www.infoq.com/cn/artic...
三、redis集群介绍和搭建测试：
http://blog.csdn.net/zhu_tian...
http://blog.csdn.net/zhu_tian...
http://blog.csdn.net/zhu_tian...
http://redisdoc.com/topic/clu...
http://www.cnblogs.com/gomysq...
四、redis rpm包仓库：
https://www.rpmfind.net/linux...
五、redis-trib.rb讲解
http://weizijun.cn/2016/01/08...
2016年10月18日发布 更多
