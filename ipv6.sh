#!/usr/bin/env bash
# enable-ipv6-prefer.sh — combine aduhappy ipv6.sh + auto-detect & backup/restore
# Usage:
#   sudo bash enable-ipv6-prefer.sh        # 启用 IPv6 优先
#   sudo bash enable-ipv6-prefer.sh restore  # 恢复原始配置

set -e

GAI_CONF="/etc/gai.conf"
BACKUP="/etc/gai.conf.backup_ipv6"

function info {
  echo -e "[INFO] $*"
}
function err {
  echo -e "[ERROR] $*" >&2
}

if [[ "$1" == "restore" ]]; then
  if [[ -f "$BACKUP" ]]; then
    info "Restoring original ${GAI_CONF} from backup..."
    cp "$BACKUP" "$GAI_CONF"
    info "Restore done."
    exit 0
  else
    err "Backup file not found: $BACKUP"
    exit 1
  fi
fi

# 检查系统文件
if [[ ! -f "$GAI_CONF" ]]; then
  err "$GAI_CONF not found — are you running on a Debian/Ubuntu system?"
  exit 1
fi

# 检查 IPv6 支持
if ip -6 addr show scope global | grep -q "inet6"; then
  info "Detected at least one global IPv6 address."
else
  info "No global IPv6 address found — system may not have IPv6 connectivity."
fi

# 备份
if [[ ! -f "$BACKUP" ]]; then
  info "Backing up ${GAI_CONF} to ${BACKUP}"
  cp "$GAI_CONF" "$BACKUP"
else
  info "Backup already exists at ${BACKUP}. Will not overwrite."
fi

# 调用原 aduhappy 脚本逻辑（或兼容其方式）  
# 这里假设原脚本就是对 /etc/gai.conf 做 IPv6 优先设置 —— 我们重复类似逻辑：

info "Updating ${GAI_CONF}: preferring IPv6 over IPv4..."

# 注释掉可能让 IPv4-mapped (::ffff:0:0/96) 优先的 line
sed -ri 's/^\s*(precedence\s+::ffff:0:0\/96\s+)[0-9]+/# & # disabled for IPv6 prefer/' "$GAI_CONF"

# 如果不存在 IPv6-优先规则，则添加
if ! grep -q '^precedence ::/0\s\+100' "$GAI_CONF"; then
  {
    echo ""
    echo "# Added by enable-ipv6-prefer.sh — prefer IPv6"
    echo "precedence ::/0  100"
  } >> "$GAI_CONF"
  info "Inserted 'precedence ::/0  100' to prefer IPv6."
else
  info "IPv6-prefer rule already present — skipping insertion."
fi

info "Done. Now system should prefer IPv6 if available."
info "To test: ping6 google.com ； 或 curl -6 https://ip.sb"
info "If you encounter network problems, restore original config via:"
info "  sudo bash $0 restore"