#!/bin/bash

echo "Hello Chenghao!"
echo "Hello Chenghao! Nice to Meet you in $(date)" >> /root/logs.txt

# Step 1: 配置 .ssh/id_rsa 和权限
setup_ssh_keys() {
    mkdir -p ~/.ssh
    echo "$HUGGINGFACE_RSA_PRIVATE_KEY" > ~/.ssh/id_rsa
    echo "$HUGGINGFACE_RSA_PUBLIC_KEY" > ~/.ssh/id_rsa.pub
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
    ssh-keyscan -H huggingface.co >> ~/.ssh/known_hosts 2>/dev/null
}

# Step 2: 克隆仓库（不拉取 LFS 文件）
clone_hf_repo() {
    git clone --depth 1 --filter=blob:none https://huggingface.co/datasets/megatrump/test repo
}

# Step 3: 创建 hf_upload 函数
hf_upload() {
    local file_path="$1"
    local repo_path="repo"
    
    if [[ ! -d "$repo_path" ]]; then
        echo "Repository not found! Ensure it is cloned before uploading."
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "File $file_path does not exist."
        return 1
    fi

    local file_name=$(basename "$file_path")
    local file_size=$(stat -c%s "$file_path")
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')

    # 拷贝文件到仓库
    cp "$file_path" "$repo_path/"
    cd "$repo_path" || return 1

    # 配置 LFS 和 Git
    git lfs install
    git lfs track "$file_name"
    git add "$file_name"
    git commit -m "Adding ${current_time}-${file_size}-${file_name} to LFS"
    git push

    cd - || return 1
}

# 执行初始化
setup_ssh_keys
clone_hf_repo

