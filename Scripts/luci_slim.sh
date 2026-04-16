#!/bin/bash
set -e

echo "======================================"
echo " OpenWrt LuCI Hide Menu Script"
echo " Safe mode (hidden=true)"
echo "======================================"

LUCI_FEEDS="package/feeds/luci"

# =========================
# 通用函数：给某菜单块加 hidden
# =========================
add_hidden() {
    local pattern="$1"
    local file="$2"

    if grep -q "$pattern" "$file"; then
        # 已经有 hidden 就跳过
        if ! grep -A3 "$pattern" "$file" | grep -q '"hidden"'; then
            sed -i "/$pattern/a\        \"hidden\": true," "$file"
            echo "  ✔ hidden added -> $pattern"
        else
            echo "  ✔ already hidden -> $pattern"
        fi
    fi
}

# =========================
# 1. System Plugins
# =========================
echo "[1] Hide System Plugins..."

SYS_FILE="$LUCI_FEEDS/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json"

if [ -f "$SYS_FILE" ]; then
    add_hidden '"admin/system/plugins": {' "$SYS_FILE"
else
    echo "  ⚠ luci-mod-system.json not found"
fi

# =========================
# 2. OLSR Plugins
# =========================
echo "[2] Hide OLSR Plugins..."

if [ -d "$LUCI_FEEDS/applications/luci-app-olsr" ]; then

    find "$LUCI_FEEDS/applications/luci-app-olsr" \
        -type f -name "*.json" | while read f; do

        add_hidden 'olsrd/plugins": {' "$f"
        add_hidden 'olsrd6/plugins": {' "$f"

    done

    echo "  ✔ OLSR plugins hidden"
else
    echo "  ⚠ luci-app-olsr not found"
fi
