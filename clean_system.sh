#!/bin/bash

# 自动清理Linux系统垃圾文件脚本
# 功能：清理日志、临时文件、缓存、旧内核等
# 作者：tangdino
# 版本：v1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误：此脚本需要root权限！${NC}"
    exit 1
fi
# 1. 清理日志文件（保留最近7天）
echo -e "${GREEN}[1/5] 正在清理旧日志...${NC}"
find /var/log -type f -name "*.log" -mtime +7 -delete
journalctl --vacuum-time=7d 2>/dev/null
echo -e "   ${GREEN}✓ 日志清理完成${NC}"

# 2. 清理临时文件
echo -e "${GREEN}[2/5] 正在清理临时文件...${NC}"
rm -rf /tmp/* 2>/dev/null
rm -rf /var/tmp/* 2>/dev/null
echo -e "   ${GREEN}✓ 临时文件清理完成${NC}"

# 3. 清理APT缓存（Ubuntu/Debian）
if command -v apt-get &>/dev/null; then
    echo -e "${GREEN}[3/5] 正在清理APT缓存...${NC}"
    apt-get clean
    apt-get autoclean
    echo -e "   ${GREEN}✓ APT缓存清理完成${NC}"
fi

# 4. 清理YUM/DNF缓存（CentOS/RHEL/Fedora）
if command -v dnf &>/dev/null; then
    echo -e "${GREEN}[3/5] 正在清理DNF缓存...${NC}"
    dnf clean all
elif command -v yum &>/dev/null; then
    echo -e "${GREEN}[3/5] 正在清理YUM缓存...${NC}"
    yum clean all
fi

# 5. 清理旧内核（仅保留当前和上一个版本）
if command -v apt-get &>/dev/null; then
    echo -e "${GREEN}[4/5] 正在清理旧内核...${NC}"
    current_kernel=$(uname -r)
    installed_kernels=$(dpkg --list | grep linux-image | awk '{print $2}')
    for kernel in $installed_kernels; do
        if [[ ! "$kernel" =~ "$current_kernel" ]] && [[ ! "$kernel" =~ $(echo "$current_kernel" | cut -d'-' -f1) ]]; then
            apt-get purge -y "$kernel"
        fi
    done
    echo -e "   ${GREEN}✓ 旧内核清理完成${NC}"
fi

# 6. 清理用户缓存
echo -e "${GREEN}[5/5] 正在清理用户缓存...${NC}"
find /home -type f -name "*.tmp" -delete
find /home -type f -name "*.cache" -delete
echo -e "   ${GREEN}✓ 用户缓存清理完成${NC}"

# 7. 全面清理 Docker 未使用的资源（容器、镜像、网络、缓存等）
if command -v docker &>/dev/null; then
    echo -e "${GREEN}[6/6] 正在全面清理 Docker 垃圾...${NC}"
    docker system prune -af 2>/dev/null
    echo -e "   ${GREEN}✓ Docker 系统清理完成${NC}"
fi

# 显示清理结果
echo -e "\n${GREEN}✅ 系统清理完成！${NC}"
