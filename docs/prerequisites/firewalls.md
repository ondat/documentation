---
title: "Firewalls"
linkTitle: Firewalls
weight: 200
---

## Port list

Ondat daemons listen on specific ports, which we require to be accessible
between all nodes in the cluster:

| Port Number   | TCP/UDP     | Use                     |
| :-----------: | :---------: | :---------------------- |
| 5701          | TCP         | gRPC                    |
| 5703          | TCP         | DirectFS                |
| 5704          | TCP         | Dataplane Supervisor    |
| 5705          | TCP         | REST API                |
| 5711          | TCP & UDP   | Gossip service          |
| 25705-25960   | TCP         | RWX Volume Endpoints    |

> 💡 Ondat also uses [ephemeral](https://en.wikipedia.org/wiki/Ephemeral_port)
> ports to dial-out to these ports on other Ondat nodes. For this reason,
> outgoing traffic should to other nodes be enabled.

## Firewalls and VPS providers

Some VPS providers (such as Digital Ocean) ship default firewall rulesets which
must be updated to allow Ondat to run. Some example rules are shown below -
modify to taste.

### UFW

For distributions using UFW, such as RHEL and derivatives:

```bash
ufw default allow outgoing
ufw allow 5701:5711/tcp
ufw allow 5711/udp
ufw allow 25705:25960/tcp
```

### Firewalld

For distributions that enable firewalld to control iptables such as some installations of OpenShift.

```bash
firewall-cmd --permanent  --new-service=storageos
firewall-cmd --permanent  --service=storageos --add-port=5700-5800/tcp --add-port=25705-25960/tcp
firewall-cmd --add-service=storageos  --zone=public --permanent
firewall-cmd --reload
```

### Iptables

For those using plain iptables:

```bash
# Inbound traffic
iptables -I INPUT -i lo -m comment --comment 'Permit loopback traffic' -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -m comment --comment 'Permit established traffic' -j ACCEPT
iptables -I INPUT -p tcp --dport 5701:5711 -m comment --comment 'Ondat' -j ACCEPT
iptables -I INPUT -p udp --dport 5711 -m comment --comment 'Ondat' -j ACCEPT
iptables -I INPUT -p tcp --dport 25705:25960 -m comment --comment 'Ondat' -j ACCEPT

# Outbound traffic
iptables -I OUTPUT -o lo -m comment --comment 'Permit loopback traffic' -j ACCEPT
iptables -I OUTPUT -d 0.0.0.0/0 -m comment --comment 'Permit outbound traffic' -j ACCEPT
```

> ⚠️ Please ensure that the iptables rules you have added above come before any default DROP or REJECT rules.
