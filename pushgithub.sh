#!/bin/bash

# 提示用户输入提交信息
read -p "请输入提交信息: " commit_message
current_branch=$(git branch --show-current)
echo "current branch= $current_branch"
# 执行 Git 命令
#git add -u
git add .
git commit -m "$commit_message $(date '+%b %d')"
git push origin $current_branch

echo "Git 命令已执行完毕。"
