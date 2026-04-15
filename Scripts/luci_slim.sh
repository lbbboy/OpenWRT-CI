#!/bin/bash
# System Plugins
sed -i '/admin\/system\/plugins/,/},/d' feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json

# OLSR Plugins
grep -rl 'olsrd/plugins' feeds/luci | xargs sed -i '/plugins/d'
