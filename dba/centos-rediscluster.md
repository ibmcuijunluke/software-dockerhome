这里创建6个Redis节点，其中三个为主节点，三个为从节点。

redis和端口对应关系：

127.0.0.1:7000
127.0.0.1:7001

127.0.0.1:7002

从：

127.0.0.1:7003
127.0.0.1:7004
127.0.0.1:7005

步骤：
1,下载redis。官网下载3.0.0版本，之前几的版本不支持集群模式
下载地址：http://download.redis.io/releases/redis-3.0.0.tar.gz


2：上传服务器，解压，编译
tar -zxvf redis-3.0.0.tar.gz
mv redis-3.0.0 redis3.0
cd /usr/local/redis3.0
make & make install


3：创建集群需要的目录并拷贝redis
mkdir -p /usr/local/cluster
mkdir -p /usr/local/cluster/7000
mkdir -p /usr/local/cluster/7001
mkdir -p /usr/local/cluster/7002
mkdir -p /usr/local/cluster/7003
mkdir -p /usr/local/cluster/7004
mkdir -p /usr/local/cluster/7005
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7000/
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7001/
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7002/
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7003/
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7004/
cp -rf /usr/local/redis3.0/* /usr/local/cluster/7005/


4：修改配置文件redis.conf

vi /usr/local/cluster/7000/redis.conf

##修改配置文件中的下面选项
port 7000
daemonize yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes


#同样再对其它配置文件进行修改
vi /usr/local/cluster/7001/redis.conf
vi /usr/local/cluster/7002/redis.conf
vi /usr/local/cluster/7003/redis.conf
vi /usr/local/cluster/7004/redis.conf
vi /usr/local/cluster/7005/redis.conf
##注意：不同的目录配置不同的redis.conf中的port


5：启动6个redis

cd /usr/local/cluster/7000/src
redis-server ../redis.conf
cd /usr/local/cluster/7001/src
redis-server ../redis.conf
cd /usr/local/cluster/7002/src
redis-server ../redis.conf
cd /usr/local/cluster/7003/src
redis-server ../redis.conf
cd /usr/local/cluster/7004/src
redis-server ../redis.conf
cd /usr/local/cluster/7005/src
redis-server ../redis.conf

##启动之后使用命令查看redis的启动情况ps -ef|grep redis


6,创建redis集群
cd /usr/local/redis3.0/src
./redis-trib.rb  create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005

6.1执行上面的命令的时候会报错，因为是执行的的脚本，需要
错误内容：/usr/bin/env: ruby: No such file or directory
所以需要安装ruby的环境，这里推荐使用yum install ruby


yum install ruby


6.2然后再执行第步的创建集群命令，还会报错，提示缺少rubygems组件
错误内容：
./redis-trib.rb:24:in `require': no such file to load -- rubygems (LoadError)
from ./redis-trib.rb:24
yum install rubygems


6.3再次执行第步的命令，还会报错，提示不能加载redis，是因为缺少redis的接口
错误内容：
/usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `gem_original_require': no such file to load -- redis (LoadError)
from /usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `require'
from ./redis-trib.rb:25


gem install redis
这里可能无法安装,因为无法连接gem服务器：
[@zw_22_90 src]# gem install redis --version 3.0.0  
ERROR:  Could not find a valid gem 'redis' (= 3.0.0) in any repository
ERROR:  While executing gem ... (Gem::RemoteFetcher::FetchError)


需要手工下载并安装：
wget https://rubygems.global.ssl.fastly.net/gems/redis-3.2.1.gem
gem install -l ./redis-3.2.1.gem


6.4 再次执行第步的命令，正常执行
输入yes，然后配置完成。
[@zw_22_90 src]# ./redis-trib.rb  create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
>>> Creating cluster
Connecting to node 127.0.0.1:7000: OK
Connecting to node 127.0.0.1:7001: OK
Connecting to node 127.0.0.1:7002: OK
Connecting to node 127.0.0.1:7003: OK
Connecting to node 127.0.0.1:7004: OK
Connecting to node 127.0.0.1:7005: OK
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
127.0.0.1:7000
127.0.0.1:7001
127.0.0.1:7002
Adding replica 127.0.0.1:7003 to 127.0.0.1:7000
Adding replica 127.0.0.1:7004 to 127.0.0.1:7001
Adding replica 127.0.0.1:7005 to 127.0.0.1:7002
M: 2022f24d581b4a7c3342e3245c32927cbd5ec16d 127.0.0.1:7000
   slots:0-5460 (5461 slots) master
M: 37b7008f80f8c21a698da8cb1f1b32db8c0c415c 127.0.0.1:7001
   slots:5461-10922 (5462 slots) master
M: ac6dc5fa96e856b34c1ba4c3814394e4ebb698dd 127.0.0.1:7002
   slots:10923-16383 (5461 slots) master
S: b5b76d70bbb0dbf3e7df8a38f1259e95e2054721 127.0.0.1:7003
   replicates 2022f24d581b4a7c3342e3245c32927cbd5ec16d
S: 6881f8fef9c25da486f320ebf2ead39c1502db4c 127.0.0.1:7004
   replicates 37b7008f80f8c21a698da8cb1f1b32db8c0c415c
S: f090526d32cced97731eef2a2e1722a7bac7d9ea 127.0.0.1:7005
   replicates ac6dc5fa96e856b34c1ba4c3814394e4ebb698dd
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join...
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: 2022f24d581b4a7c3342e3245c32927cbd5ec16d 127.0.0.1:7000
   slots:0-5460 (5461 slots) master
M: 37b7008f80f8c21a698da8cb1f1b32db8c0c415c 127.0.0.1:7001
   slots:5461-10922 (5462 slots) master
M: ac6dc5fa96e856b34c1ba4c3814394e4ebb698dd 127.0.0.1:7002
   slots:10923-16383 (5461 slots) master
M: b5b76d70bbb0dbf3e7df8a38f1259e95e2054721 127.0.0.1:7003
   slots: (0 slots) master
   replicates 2022f24d581b4a7c3342e3245c32927cbd5ec16d
M: 6881f8fef9c25da486f320ebf2ead39c1502db4c 127.0.0.1:7004
   slots: (0 slots) master
   replicates 37b7008f80f8c21a698da8cb1f1b32db8c0c415c
M: f090526d32cced97731eef2a2e1722a7bac7d9ea 127.0.0.1:7005
   slots: (0 slots) master
   replicates ac6dc5fa96e856b34c1ba4c3814394e4ebb698dd
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.


至此redis集群即搭建成功！


7，redis-cli命令进入集群环境
[@zw_22_90 src]# redis-cli -c -p 7000
127.0.0.1:7000> quit;



参考了：http://blog.csdn.NET/xu470438000/article/details/42971091，并进行了细节修改和部分补充。



今天又在公司搭建了一个集群，记录操作命令如下：

cd ~
wget http://download.redis.io/releases/redis-3.0.0.tar.gz
tar -zxvf redis-3.0.0.tar.gz
mv redis-3.0.0 redis3
cd redis3
make & make install


mkdir /opt/soft/redis3_master
mkdir /opt/soft/redis3_slave


cp -rf ~/redis3/* /opt/soft/redis3_master
cp -rf ~/redis3/* /opt/soft/redis3_slave


vi /opt/soft/redis3_master/redis.conf
=========================
#修改这几个参数为：
# <---edit by dafei
port 7001
logfile "/opt/soft/redis3_slave/log.log"
daemonize yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-require-full-coverage yes
appendonly no
# edit by dafei --->
=========================


vi /opt/soft/redis3_slave/redis.conf
=========================
#修改这几个参数为：
# <---edit by dafei
port 7002
logfile "/opt/soft/redis3_slave/log.log"
daemonize yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-require-full-coverage yes
appendonly no
# edit by dafei --->
=========================


#start
cd /opt/soft/redis3_master/src
redis-server ../redis.conf
cd /opt/soft/redis3_slave/src
redis-server ../redis.conf




#start the cluster at 10.10.22.95
./redis-trib.rb  create --replicas 1 ip:7001 ip:7001 ip:7001 ip:7002 ip:7002 ip:7002
#上面这个start报错，可参考：http://blog.csdn.Net/lifeiaidajia/article/details/45370377
