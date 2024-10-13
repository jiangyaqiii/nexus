#!/bin/bash

# 定义服务名称和文件路径
SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/nexus.service"  # 更新服务文件路径

# 脚本保存路径
SCRIPT_PATH="$HOME/nexus.sh"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

    # 检查服务是否正在运行
    if systemctl is-active --quiet nexus.service; then
        echo "nexus.service 当前正在运行。正在停止并禁用它..."
        sudo systemctl stop nexus.service
        sudo systemctl disable nexus.service
    else
        echo "nexus.service 当前未运行。"
    fi

    # 确保目录存在
    mkdir -p /root/.nexus  # 创建目录（如果不存在）

    # 更新系统并安装必要的软件包
    echo "更新系统并安装必要的软件包..."
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y; then
        echo "安装软件包失败。"  # 错误信息
        exit 1
    fi
    
    # 检查并安装 Git
    if ! command -v git &> /dev/null; then
        echo "Git 未安装。正在安装 Git..."
        if ! sudo apt install git -y; then
            echo "安装 Git 失败。"  # 错误信息
            exit 1
        fi
    else
        echo "Git 已安装。"  # 成功信息
    fi

    # 检查 Rust 是否已安装
    if command -v rustc &> /dev/null; then
        echo "Rust 已安装，版本为: $(rustc --version)"
    else
        echo "Rust 未安装，正在安装 Rust..."
        # 使用 rustup 安装 Rust
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        echo "Rust 安装完成。"
        
        # 加载 Rust 环境
        source $HOME/.cargo/env
        export PATH="$HOME/.cargo/bin:$PATH"
        echo "Rust 环境已加载。"
    fi

    if [ -d "$HOME/network-api" ]; then
    show "正在删除现有的仓库..." "progress"
    rm -rf "$HOME/network-api"
    fi
    
    # 克隆指定的 GitHub 仓库
    echo "正在克隆仓库..."
    cd
    git clone https://github.com/nexus-xyz/network-api.git

    # 安装依赖项
    cd $HOME/network-api/clients/cli
    echo "安装所需的依赖项..." 
    if ! sudo apt install pkg-config libssl-dev -y; then
        echo "安装依赖项失败。"  # 错误信息
        exit 1
    fi
    
    # 创建 systemd 服务文件
    echo "创建 systemd 服务..." 
    if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
Environment=PATH=/root/.cargo/bin:$PATH
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
        echo "创建 systemd 服务文件失败。" 
        exit 1
    fi

    # 重新加载 systemd 并启动服务
    echo "重新加载 systemd 并启动服务..." 
    if ! sudo systemctl daemon-reload; then
        echo "重新加载 systemd 失败。"
        exit 1
    fi

    if ! sudo systemctl start nexus.service; then
        echo "启动服务失败。" 
        exit 1
    fi

    if ! sudo systemctl enable nexus.service; then
        echo "启用服务失败。" 
        exit 1
    fi

    echo "节点启动成功！"
  cd
  rm start.sh
