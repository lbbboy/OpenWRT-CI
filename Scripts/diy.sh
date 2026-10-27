#!/bin/bash

# 隐藏顶部左侧的品牌文字
cat >> package/feeds/luci/luci-theme-material/htdocs/luci-static/material/custom.css <<'EOF'

a.brand {
    display: none !important;
}
EOF


cat << 'EOF' > feeds/luci/applications/luci-app-arpbind/root/etc/init.d/arpbind
#!/bin/sh /etc/rc.common

START=80
STOP=20

# 必须声明此项，否则 service_triggers 和 procd 重载机制将失效
USE_PROCD=1

# 添加静态ARP（使用 replace 避免 File exists 报错）
add_arp() {
    local ip="$1"
    local mac="$2"
    local ifname="$3"
    [ -z "$ip" ] || [ -z "$mac" ] || [ -z "$ifname" ] && return
    
    # 过滤掉非法的星号配置，防止内核报错
    if [ "$mac" = "*" ]; then
        echo "Error: Invalid MAC address '*' for IP $ip"
        return 1
    fi

    echo "Adding ARP: IP $ip  MAC $mac  Interface $ifname"
    ip neigh replace "$ip" lladdr "$mac" nud permanent dev "$ifname"
}

# 删除配置里的静态ARP
del_arp() {
    local ip="$1"
    local ifname="$2"
    [ -z "$ip" ] || [ -z "$ifname" ] && return
    echo "Deleting ARP: IP $ip  Interface $ifname"
    ip neigh del "$ip" dev "$ifname" 2>/dev/null
}

# 遍历配置执行添加
arpconf_foreach() {
    local cfg="$1"
    local enabled ip mac ifname
    
    # 读取启用状态，默认缺省为 1 (开启)
    config_get_bool enabled "$cfg" "enabled" "1"
    [ "$enabled" -eq "1" ] || return 0
    
    config_get ip "$cfg" "ipaddr"
    config_get mac "$cfg" "macaddr"
    config_get ifname "$cfg" "ifname"
    [ -n "$ip" ] && [ -n "$mac" ] && [ -n "$ifname" ] && add_arp "$ip" "$mac" "$ifname"
}

# 遍历配置执行删除
arpconf_foreach_del() {
    local cfg="$1"
    local ip ifname
    config_get ip "$cfg" "ipaddr"
    config_get ifname "$cfg" "ifname"
    [ -n "$ip" ] && [ -n "$ifname" ] && del_arp "$ip" "$ifname"
}

# 启动服务
start_service() {
    config_load "arpbind"
    config_foreach arpconf_foreach "arpbind"
}

# 停止服务
stop_service() {
    config_load "arpbind"
    config_foreach arpconf_foreach_del "arpbind"
}

# 配置文件变更触发
service_triggers() {
    procd_add_reload_trigger "arpbind"
}
EOF
