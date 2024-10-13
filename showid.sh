    if [ -f /root/.nexus/prover-id ]; then
        echo "Prover ID 内容:"
        echo "$(</root/.nexus/prover-id)"  # 使用 echo 显示文件内容
    else
        echo "文件 /root/.nexus/prover-id 不存在。"
    fi
