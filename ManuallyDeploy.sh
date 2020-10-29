!#/bin/bash
一.基础环境设置
1.1 关闭防火墙和selinux

for i in {161..164};do ssh 10.100.201.$i "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g'" /etc/selinux/config;done
for i in {161..164};do ssh 10.100.201.$i "systemctl stop firewalld && systemctl disable firewalld";done

1.2 设置主机名
for i in {161..164};do ssh 10.100.201.$i "hostnamectl set-hostname ceph$(ip a)";done

1.3 设置chrony和 timezone
for i in {161..164};do ssh 10.100.201.$i "yum install chrony -y";done
for i in {161..164};do ssh 10.100.201.$i "systemctl enable chronyd";done
echo <<END> /etc/chrony.conf
server 127.0.0.1. iburst
driftfile /var/lib/chrony/drift
stratumweight 0
makestep 1 -1
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
rtcsync
allow 10.100.201.0/24
local stratum 10
keyfile /etc/chrony.keys
logdir /var/log/chrony
log measurements statistics tracking
END
for i in {162..164};do ssh 10.100.201.$i "sed -i -e '/server*/'d -e '4a\server 10.100.201.161 iburst' /etc/chrony.conf";done
for i in {161..164};do ssh 10.100.201.$i "systemctl restart chronyd";done
for i in {161..164};do ssh 10.100.201.$i "chronyc sources";done

1.4 设置/etc/hosts

##设置/etc/hosts

cat <<END> /etc/hosts
10.100.201.161 ceph01
10.100.201.162 ceph02
10.100.201.163 ceph03
10.100.201.164 ceph04
END


1.5 设置无密码访问
ssh-keygen
for i in {161..164};do ssh-copy-id -i .ssh/id_rsa.pub root@10.100.201.$i;done

1.6 设置yum 源
#下载aliyunyum 源代替本地源
#https://developer.aliyun.com/mirror/centos?spm=a2c6h.13651102.0.0.3e221b11joUPSR
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
#or
#curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

#epel
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#ceph yum 源
#https://mirrors.aliyun.com/ceph/
rpm -ivh https://mirrors.aliyun.com/ceph/rpm-octopus/el7/SRPMS/ceph-release-1-1.el7.src.rpm

1.7 安装基础包
yum-plugin-priorities
snappy leveldb gdisk python-argparse gperftools-libs wget
1.8 更新系统

二. 部署Ceph
2.1 安装
yum install ceph-deploy -y
2.2 增加ceph 用户
useradd Cephx
cd /home/Cephx

passwd Cephx
###设置权限
echo "Cephx ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/Cephx
Cephx ALL = (root) NOPASSWD:ALL
[root@ceph01 ~]# chmod 0440 /etc/sudoers.d/Cephx

2.3 初始化Ceph 集群
cd /home/Cephx
mkdir myceph
cd myceph

ceph-deploy new ceph{01..03}
###安装软件
ceph-deploy install ceph{01..04} --no-adjust-repos
ceph-deploy mon create-initial
cat <<END>> /home/Cephx/myceph/ceph.conf
public_network=10.100.201.0/24
cluster_network=119.119.119.0/24
END


##20200930 部署到修改 public network 和cluster network
#同步配置文件
cd /home/Cephx/myceph
ceph-deploy --overwrite-conf admin ceph{01..03}

2.4 创建osd 盘
###创建OSD 过程
##格式化盘
ceph-volume lvm zap /dev/sdb
ceph-volume lvm zap /dev/sdc
###创建osd 盘 blustore方式无journal盘
ceph-deploy osd create ceph04 --data /dev/sdc

2.5 开启 dashboard 和prometheus
[root@ceph01 ceph]# ceph mgr module enable dashboard
[root@ceph01 ceph]# ceph mgr module enable prometheus
module 'dashboard' is already enabled
[root@ceph01 ceph]# ceph dashboard create-self-signed-cert
Self-signed certificate created
[root@ceph01 ceph]# ceph dashboard set-login-credentials admin admin
Username and password updated
[root@ceph01 ceph]# sudo ceph mgr services
{
    "dashboard": "https://ceph04:8443/",
    "prometheus": "http://ceph04:9283/"
}

###web: https://ceph04:8443
