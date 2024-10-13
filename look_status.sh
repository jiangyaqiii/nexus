#!/bin/bash

# 获取服务状态
STATUS=$(systemctl is-active nexus.service)

# 判断服务状态并输出相应信息
if [ "$STATUS" = "active" ]; then
    echo "Nexus service is active and running! 🎉"
else
    echo "Nexus service is not running. 🚫"
fi
