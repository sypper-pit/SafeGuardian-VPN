#!/bin/bash


apt update && apt upgrade -y && apt install lxc -y && wait

sleep 10 && wait

cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv4.nat: true
    ipv6.address: none
  description: ""
  name: wan0
  type: ""
  project: default
- config:
    ipv4.address: 10.0.4.1/24
    ipv4.nat: false
    ipv4.dhcp: true
    ipv6.address: none
  description: ""
  name: lan0
  type: ""
  project: default
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: wan0
      type: nic
    eth1:
      name: eth1
      network: lan0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF
