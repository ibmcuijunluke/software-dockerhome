redis主从和mysql主从目的差不多，但redis主从配置很简单，主要在从节点配置文件指定主节点ip和端口：slaveof 192.168.1.197 6379，然后启动主从，主从就搭建好了redis主从中如果主节点发生故障，不会自动切换，需要借助redis的Sentinel或者keepalive来实现主的故障转移

redis集群是一个无中心的分布式redis存储架构，可以在多个节点之间进行数据共享，解决了redis高可用、可扩展等问题，redis集群提供了以下两个好处
1、将数据自动切分(split)到多个节点
2、当集群中的某一个节点故障时，redis还可以继续处理客户端的请求。
一个 Redis 集群包含 16384 个哈希槽（hash slot），数据库中的每个数据都属于这16384个哈希槽中的一个。集群使用公式 CRC16(key) % 16384 来计算键 key 属于哪个槽。集群中的每一个节点负责处理一部分哈希槽。
集群中的主从复制
集群中的每个节点都有1个至N个复制品，其中一个为主节点，其余的为从节点，如果主节点下线了，集群就会把这个主节点的一个从节点设置为新的主节点，继续工作。这样集群就不会因为一个主节点的下线而无法正常工作


下面开始搭建redis集群

由于最小的redis集群需要3个主节点，一台机器可运行多个redis实例，我搭建时使用两台机器，6个redis实例，其中三个主节点，三个从节点作为备份
网上很多使用单台服务器开6个端口，操作差不多，只是配置基本相对简单点，多台服务器更接近生产环境

redis 6个节点的ip和端口对应关系
server1:
192.168.1.198:7000
192.168.1.198:7001
192.168.1.198:7002
server2：
192.168.1.199:7003
192.168.1.199:7004
192.168.1.199:7005

1、安装需要的依赖包


[root@localhost ~]# yum install gcc gcc-c++ kernel-devel automake autoconf libtool make wget tcl vim ruby rubygems unzip git -y

2、两台机器分别下载redis并安装


[root@localhost src]# cd /usr/local/
[root@localhost local]# wget http://download.redis.io/releases/redis-3.0.6.tar.gz
[root@localhost local]# tar xzf redis-3.0.6.tar.gz
[root@localhost local]# cd redis-3.0.6
[root@localhost redis-3.0.6]# make


3、创建集群需要的目录

server1执行：

mkdir -p /usr/local/cluster
cd /usr/local/cluster
mkdir 7000
mkdir 7001
mkdir 7002server2执行：

mkdir -p /usr/local/cluster
cd /usr/local/cluster
mkdir 7003
mkdir 7004
mkdir 7005
4、修改配置文件redis.conf
cp /usr/local/redis-3.0.6/redis.conf  /usr/local/cluster
cd /usr/local/cluster
vi redis.conf

##注意每个实例的端口号不同
port 7000
daemonize yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes##修改完redis.conf配置文件中的这些配置项之后把这个配置文件分别拷贝到7000/7001/7002/7003/7004/7005节点目录下
server1执行：

cp /usr/local/cluster/redis.conf /usr/local/cluster/7000
cp /usr/local/cluster/redis.conf /usr/local/cluster/7001
cp /usr/local/cluster/redis.conf /usr/local/cluster/7002server2执行：

cp /usr/local/cluster/redis.conf /usr/local/cluster/7003
cp /usr/local/cluster/redis.conf /usr/local/cluster/7004
cp /usr/local/cluster/redis.conf /usr/local/cluster/7005##注意：拷贝完成之后要分别修改7001/7002/7003/7004/7005目录下面redis.conf文件中的port参数，分别改为对应的文件夹的名称

5、分别启动这6个redis实例，并查看是否成功：ps -ef|grep redis
server1执行：

[root@localhost cluster]# cd /usr/local/cluster/7000
[root@localhost 7000]# redis-server redis.conf
[root@localhost 7000]# cd /usr/local/cluster/7001
[root@localhost 7001]# redis-server redis.conf
[root@localhost 7001]# cd /usr/local/cluster/7002
[root@localhost 7002]# redis-server redis.conf
[root@localhost 7002]# ps -ef|grep redis
root      2741    1  0 09:39 ?        00:00:00 redis-server *:7000 [cluster]
root      2747    1  0 09:40 ?        00:00:00 redis-server *:7001 [cluster]
root      2751    1  0 09:40 ?        00:00:00 redis-server *:7002 [cluster]
root      2755  2687  0 09:40 pts/0    00:00:00 grep redisserver2执行：
[root@localhost cluster]# cd /usr/local/cluster/7003
[root@localhost 7003]# redis-server redis.conf
[root@localhost 7003]# cd /usr/local/cluster/7004
[root@localhost 7004]# redis-server redis.conf
[root@localhost 7004]# cd /usr/local/cluster/7005
[root@localhost 7005]# redis-server redis.conf
[root@localhost 7005]# ps -ef|grep redis
root      1619    1  0 09:40 ?        00:00:00 redis-server *:7003 [cluster]
root      1623    1  0 09:40 ?        00:00:00 redis-server *:7004 [cluster]
root      1627    1  0 09:41 ?        00:00:00 redis-server *:7005 [cluster]
root      1631  1563  0 09:41 pts/0    00:00:00 grep redis


6、执行redis的创建集群命令创建集群（注意ip地址和端口号）

[root@localhost cluster]# cd /usr/local/redis-3.0.6/src
[root@localhost src]# ./redis-trib.rb  create --replicas 1 192.168.1.198:7000 192.168.1.198:7001 192.168.1.198:7002 192.168.1.199:7003 192.168.1.199:7004 192.168.1.199:70056.1到这一步因为前面第1步装了依赖包，未提示ruby和rubygems的错误，但还是会报错，提示不能加载redis，是因为缺少redis和ruby的接口，使用gem 安装
错误内容：
/usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `gem_original_require': no such file to load -- redis (LoadError)
        from /usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `require'
        from ./redis-trib.rb:25
解决：gem install redis
6.2 再次执行第6步的命令，正常执行，提示是否允许修改配置文件，输入yes，然后整个集群配置完成！
[root@localhost src]# ./redis-trib.rb  create --replicas 1 192.168.1.198:7000 192.168.1.198:7001 192.168.1.198:7002 192.168.1.199:7003 192.168.1.199:7004 192.168.1.199:7005
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
192.168.1.199:7003
192.168.1.198:7000
192.168.1.199:7004
Adding replica 192.168.1.198:7001 to 192.168.1.199:7003
Adding replica 192.168.1.199:7005 to 192.168.1.198:7000
Adding replica 192.168.1.198:7002 to 192.168.1.199:7004
M: 2f70e9f2b4a06a846e46d7034a54e0fe6971beea 192.168.1.198:7000
  slots:5461-10922 (5462 slots) master
S: e60f49920cf8620927b200b0001892d08067d065 192.168.1.198:7001
  replicates 02f1958bd5032caca2fd47a56362c8d562d7e621
S: 26101db06b5c2d4431ca8308cf43d51f6939b4fc 192.168.1.198:7002
  replicates 6c4f18b9e8729c3ab5d43b00b0bc1e2ee976f299
M: 02f1958bd5032caca2fd47a56362c8d562d7e621 192.168.1.199:7003
  slots:0-5460 (5461 slots) master
M: 6c4f18b9e8729c3ab5d43b00b0bc1e2ee976f299 192.168.1.199:7004
  slots:10923-16383 (5461 slots) master
S: ebb27bd0a48b67a4f4e0584be27c1c909944e935 192.168.1.199:7005
  replicates 2f70e9f2b4a06a846e46d7034a54e0fe6971beea
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join...
>>> Performing Cluster Check (using node 192.168.1.198:7000)
M: 2f70e9f2b4a06a846e46d7034a54e0fe6971beea 192.168.1.198:7000
  slots:5461-10922 (5462 slots) master
M: e60f49920cf8620927b200b0001892d08067d065 192.168.1.198:7001
  slots: (0 slots) master
  replicates 02f1958bd5032caca2fd47a56362c8d562d7e621
M: 26101db06b5c2d4431ca8308cf43d51f6939b4fc 192.168.1.198:7002
  slots: (0 slots) master
  replicates 6c4f18b9e8729c3ab5d43b00b0bc1e2ee976f299
M: 02f1958bd5032caca2fd47a56362c8d562d7e621 192.168.1.199:7003
  slots:0-5460 (5461 slots) master
M: 6c4f18b9e8729c3ab5d43b00b0bc1e2ee976f299 192.168.1.199:7004
  slots:10923-16383 (5461 slots) master
M: ebb27bd0a48b67a4f4e0584be27c1c909944e935 192.168.1.199:7005
  slots: (0 slots) master
  replicates 2f70e9f2b4a06a846e46d7034a54e0fe6971beea
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.


7、测试集群

server1上登录redis客户端并执行

[root@localhost src]# redis-cli -c -p 7000
127.0.0.1:7000> get key
-> Redirected to slot [12539] located at 192.168.1.199:7004
"val"
192.168.1.199:7004> set name test
-> Redirected to slot [5798] located at 192.168.1.198:7000
OK
192.168.1.198:7000> set adress shanghai
-> Redirected to slot [1562] located at 192.168.1.199:7003
OK
192.168.1.199:7003>server2上登录redis客户端并执行


[root@localhost src]# redis-cli -c -p 7003
127.0.0.1:7003> set key val
-> Redirected to slot [12539] located at 192.168.1.199:7004
OK
192.168.1.199:7004> get keyv
"val"
192.168.1.199:7004> set key2 val2
-> Redirected to slot [4998] located at 192.168.1.199:7003
OK
192.168.1.199:7003> get key2
"val2"
192.168.1.199:7003>
