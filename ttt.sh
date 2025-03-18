#!/bin/bash
# Ubuntu专用Git项目部署脚本
# 更新时间：2025年03月16日

# 参数检查
if [ $# -ne 1 ]; then
    echo "使用方法: $0 <gitToken>"
    exit 1
fi
GIT_TOKEN=$1
REPO_URL="https://${GIT_TOKEN}@github.com/zfyadd/client_trojan.git"
TARGET_DIR="./client_trojan"

# 彩色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认

# 1. 系统级Git检测
if ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}▶ 检测到Git未安装，开始自动安装...${NC}"

    # 2. APT源更新
    sudo apt update -qq
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 软件源更新失败，请检查网络连接${NC}"
        exit 1
    fi

    # 3. 静默安装Git[1,3,5](@ref)
    sudo apt install git -y -qq
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Git安装失败，请检查APT源配置${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Git $(git --version | awk '{print $3}') 安装成功${NC}"
else
    echo -e "${GREEN}✓ 已安装Git版本: $(git --version | awk '{print $3}')${NC}"
fi

# 4. 智能克隆逻辑
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠ 目标目录已存在，执行增量更新操作${NC}"
    cd "$TARGET_DIR"
    git pull --rebase -q
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 代码更新失败，请手动解决冲突${NC}"
        exit 1
    fi
    sudo sh deploy.sh
    cd - > /dev/null
else
    echo -e "${GREEN}▶ 开始克隆仓库到: $TARGET_DIR${NC}"
    git clone --depth 1 "$REPO_URL" "$TARGET_DIR" -q
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 仓库克隆失败，请检查以下内容："
        echo -e "- 网络连通性 (尝试 ping github.com)"
        echo -e "- 仓库地址有效性"
        echo -e "- 磁盘空间状态${NC}"
        exit 1
    fi
    cd "$TARGET_DIR"
    sudo sh deploy.sh
fi

# 5. 后置验证
echo -e "\n${GREEN}✓ 部署完成！验证信息如下：${NC}"
echo -e "项目路径: $(realpath $TARGET_DIR)"
echo -e "最新提交: $(cd $TARGET_DIR && git log -1 --pretty=format:'%h - %s [%an]')"