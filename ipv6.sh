#!/usr/bin/env bash
# prefer-ipv6.sh — Enable IPv6 preferred over IPv4 on Debian/Ubuntu
# Usage:
#   sudo bash prefer-ipv6.sh       # 启用 IPv6 优先
#   sudo bash prefer-ipv6.sh restore  # 恢复原始配置

set -e

GAI_CONF="/etc/gai.conf"
BACKUP="/etc/gai.conf.backup_ipv6"

echo "=== IPv6 优先脚本 ==="

# --------------------------
# 1) 恢复模式
# --------------------------
if [[ "$1" == "restore" ]]; then
    if [[ -f "$BACKUP" ]]; then
        echo "恢复原始 gai.conf..."
        cp "$BACKUP" "$GAI_CONF"
        echo "已恢复。"
        exit 0
    else
        echo "没有找到备份文件：$BACKUP"
        exit 1
    fi
fi

# --------------------------
# 2) 检查 IPv6 支持
# --------------------------
echo "- 检查 IPv6 是否启用..."
if ip addr | grep -q "inet6"; then
    echo "✓ 本机已启用 IPv6"
else
    echo "✗ 未发现 IPv6 地址，本脚本仍会修改优先级，但你可能无法使用 IPv6"
fi

# --------------------------
# 3) 备份 gai.conf
# --------------------------
if [[ ! -f "$BACKUP" ]]; then
    echo "- 备份 $GAI_CONF 到 $BACKUP"
    cp "$GAI_CONF" "$BACKUP"
else
    echo "- 已存在备份：$BACKUP（不会覆盖）"
fi

# --------------------------
# 4) 删除旧的 IPv4 优先规则
# --------------------------
echo "- 移除旧的 IPv4 优先 precedence(::ffff:0:0/96)"
sed -i 's/^\s*precedence\s\+::ffff:0:0\/96\s\+[0-9]\+/# & # disabled for IPv6 prefer/' "$GAI_CONF"

# --------------------------
# 5) 添加 IPv6 优先规则（若不存在）
# --------------------------
if ! grep -q "precedence ::/0  100" "$GAI_CONF"; then
    echo "- 添加 IPv6 优先规则"
    {
        echo ""
        echo "# Prefer IPv6 over IPv4"
        echo "precedence ::/0  100"
    } >> "$GAI_CONF"
else
    echo "- 已存在 IPv6 优先规则，跳过"
fi

echo ""
echo "=== 完成 ==="
echo "现在系统将优先使用 IPv6。你可以测试："
echo "  ping6 google.com"
echo "  curl -6 https://ip.sb"
echo ""
echo "如需恢复原来的配置："
echo "  sudo bash prefer-ipv6.sh restore"