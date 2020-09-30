if [ -e '/tmp/ceph_key_id.rsa' ]
 then
   echo "file exit"
else
  ssh-keygen -t rsa -b 2048 -f /tmp/ceph_key_id_rsa -q -N ''
fi
####if [ -e '/tmp/ceph_key_id_rsa' ] ;then echo 'file exit' ;else ssh-keygen -t rsa -b 2048 -f /tmp/ceph_key_id_rsa -q -N '';fi