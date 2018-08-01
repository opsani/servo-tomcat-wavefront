# Optune Servo with Tomcat (adjust) and Wavefront (measure) drivers

## Build servo container
```
docker build . -t example.com/servo-tomcat-wavefront
```

## Running servo as a Docker container installed from EC2 userdata

```
#!/bin/bash

# Config
DOCKER_IMG=opsani/servo-tomcat-wavefront
OPTUNE_AUTH_TOKEN=changeme
OPTUNE_ACCOUNT=dev.opsani.com
OPTUNE_APP_ID=my-app

# Install docker if not present
if ! rpm -q docker-ce; then
    # Install docer-ce dependancy from CentOS 7 repo
    extra_repo=http://mirror.centos.org/centos/7/extras/x86_64/Packages/
    pkg=$(curl -s $extra_repo|grep -o 'href="container-selinux-.*\.noarch\.rpm'|cut -d'"' -f2|tail -1)
    yum -y install http://mirror.centos.org/centos/7/extras/x86_64/Packages/$pkg

    yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

    yum install -y yum-utils device-mapper-persistent-data lvm2 docker-ce
fi
systemctl enable docker
systemctl start docker

# Pull servo image
docker pull $DOCKER_IMG

# Create Optune auth token
mkdir -p /opt/optune
echo $OPTUNE_AUTH_TOKEN > /opt/optune/auth_token
chmod 600 /opt/optune/auth_token

# Create ssh key file
cat << EOF > /opt/optune/ssh-key
-----BEGIN RSA PRIVATE KEY-----
MIIAogIBAAKCAQEAwrcO00pkUS4jgD1B28mQi9DHqdbqj4S9ytzfIAYFBADH4aJd
WoV6Y/LRgnkpm8UxCkmigcLeV65xTmSZl0FPekJ2U41dvCEKZHGjnhnliGb1vYca
mOvEOtGm5Mw5cpf0dLcSlYgd8mpTpp9bCH/fjBJjDPBqggi/hdkxVMMbFw0xOSzM
dMVp0D/JbN0Few3Kgc3adCxyK/n7mJYCBH3fhjth8MhwUot6EJAupppDbCqWGE1/
MJuglHb+wno4/6LGkhS1f96kImA2Go90r0IUUQeAyAqC90dCvkgv5oQA7mDqKgac
SnRXdJmNM/frv4SYYFDHMe8VLUF5H3Oua41RAQIDAQABAoIBACVceKTELnGBN+Cg
YGWqzGh3fAgzq7g0ETK+pLWNmeLFv5Sk0eLPn8dTzS2K0BgKgzllHaBmYsFSQH15
QhtKtdRQsmGfy2+Qq2zQfUOV1uwQvXBLXygefP2IQsy9/vvk+kv24ML+ZjigfEKJ
ay87UgqPcKAH9XfT8+Pb4+JOuYD3ek+ab+eyL5It+ThuIS9ZjHr2S/eAQvAXM/bCH
N6m5kKTGLagnpEz4+hk3f73ncRuCryHZJjF0NEG6uZNU3WN/hrGtUEvv8k3n57+6
9kuNdFCe4W5Z6NsBt43qWvrV6Cv+JwHl8fKSG0hbex7Djb0ZZW7cGcSs3bJy28lJ
6HG3KlECgYEA5+iLzA+eorpGAafLZFnwJfYALnEwU/vYU2qvT4GI5P6sdQhcL3TK
x10wak5G2/nqnaf98cNjejA6Lxw8zDy1oyTp8VHavRVBXDVguOnS76TbSgmh4wtv
2Xd149JWjUU/p1JntZQdqcZfWwbw7TkKyliHwVX3QecCvlFktqX3f90CgYEA1vFh
MI8gpP/V7AtbgCkFIscRLhSpWeg093E0xAp0RM70+Hbhi8p9EVxaOwCzrRdq2fPB
dCut59qEXN7jCqt/BGMO1fzdzt5/K9KaCglkzd15txMxNNc1EPjFdBk1T023cOQF
BPQabBQARKfkwzBw1iXiNo9OzouC8a/K5Ynx1XUCgYBqb+nRs42MhE/jLJ8GJN06
kFiu+BZFRX6I8ysZs4sgBt8iK78brM/w5o11DQ4qoi6TQ2ojDxlWGFJsEtq4plh7
U1LoBjiNtfa0mm8VD4RXpuNavMcHTNV+Cv0Zng1Jc3H+mqyswxlGNZzIS4xCZH7W
VgGgs5LzNVKmBPdjeRL6JQKBgFnYN6nWieyuS7sI3Exr2Qu6bgH2/PrpxwoPNeEk
BYmlgFxDRO/rye9xzP2Qw4n8mdtUum5Wu7CIdH9lYz3YhZVN2quzsPuBoWKt+1lq
p8otY20VBqJxumrHsbFfwBrP/3eeuEJjzo+SpLIOA99a5i99Uls/9876HdfshUEB
MibpAoGAN4SfMYNg84VfUs9v/HyXex/Yy4VPOUZvJ3GUdIfeKQuTbCcIEU4Svzka
hP/5GhvtKXohUFxhhO9jrV6uStDr/vUjUZmc9oFKnD2pe9RFcvGtkfNd/Eusv/yQ
s3i2JAy3UAVWgwvgJi7nluytjrYLv08wK1wiIJdlbmH9+cqkLHM=
-----END RSA PRIVATE KEY-----
EOF
chmod 600 /opt/optune/ssh-key

# Create config file
cat << EOF > /opt/optune/config.yaml

wavefront:
  warmup:    0   # Can be overwritted by OCO backend
  duration:  600  # Can be overwritted by OCO backend
  api_key: "d268d840-b877-418d-a316-27858e2b5b81"
  metric_name: perf
  metric_unit: 'request/s'
  granularity: 'm'
  summarization: 'LAST'
  api_host: "https://my-co.wavefront.com"
  query:  'avg(ts(appdynamics.apm.overall.avg_resp_time_ms,  env=prf and app=my-app))'
  time_aggr:   avg       # compute time-series value as the average
tomcat:
  consul_url: http://example.com/inst
  health_check_url: "http://{}:8100/jservcheck"
  health_check_timeout: 10
  health_check_ok_string: "<STATUS>OK</STATUS>"
  start_file: /path/to/tomcat.start
  restart_cmd: /path/to/tomcat.restart 0<&- >/dev/null 2>&1 &
  ssh_opts: "-o user=root -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

  components:
    gui:
      settings:
        GCTimeRatio: {}

EOF

# Start servo container
docker rm -f servo-tomcat-wavefront || true
docker run -d --restart=always \
    --name servo-tomcat-wavefront \
    -v /opt/optune/auth_token:/opt/optune/auth_token \
    -v /opt/optune/config.yaml:/servo/config.yaml \
    -v /opt/optune/ssh-key:/root/.ssh/id_rsa \
    $DOCKER_IMG --auth-token /opt/optune/auth_token \
    --account $OPTUNE_ACCOUNT $OPTUNE_APP_ID

```
