!#/bin/bash
# 基础环境设置
1.yum 源
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


ssh-keygen
for i in {161..163};do ssh-copy-id -i /root/.ssh/id_rsa.pub root@10.100.201.$i ;done


for i in {161..163};do ssh 10.100.201.$i "yum install wget -y";done


#4. 设置 selinux 和firewalld
for i in {161..164};do ssh 10.100.201.$i "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g'" /etc/selinux/config;done
for i in {161..164};do ssh 10.100.201.$i "systemctl stop firewalld && systemctl disable firewalld";done

##7.设置Hostname
for i in {161..164};do ssh 10.100.201.$i "hostnamectl set-hostname ceph$(ip a)";done
##设置/etc/hosts

cat <<END> /etc/hosts
10.100.201.161 ceph01
10.100.201.162 ceph02
10.100.201.163 ceph03
10.100.201.164 ceph04
END


for i in {161..164};do ssh 10.100.201.$i "yum install chrony -y";done
for i in {161..164};do ssh 10.100.201.$i "systemctl enable chronyd";done


