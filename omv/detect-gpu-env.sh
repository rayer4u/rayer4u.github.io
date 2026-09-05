#!/usr/bin/env bash
set -e

# ==============================================================================
# 自动探测本机硬件 (NVIDIA / APU) 与显卡设备组 GID 并配置到 .env
# ==============================================================================

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    if [ -f ".env.sample" ]; then
        echo "未找到 .env，正在从 .env.sample 复制生成..."
        cp .env.sample "$ENV_FILE"
    else
        touch "$ENV_FILE"
    fi
fi

# 1. 探测宿主机显卡组 GID
RENDER_GID=$(getent group render | cut -d: -f3 || true)
VIDEO_GID=$(getent group video | cut -d: -f3 || true)

# 兜底默认值
RENDER_GID=${RENDER_GID:-105}
VIDEO_GID=${VIDEO_GID:-44}

echo "--> 探测到宿主机显卡组 GID: RENDER_GID=${RENDER_GID}, VIDEO_GID=${VIDEO_GID}"

# 2. 探测显卡类型 (NVIDIA 独显 vs Linux 标准 DRI 通用显卡)
JELLYFIN_FILE="docker-compose.jellyfin.dri.yml"
PHOTO_FILE="docker-compose.photo.dri.yml"
PHOTO_ENC="intel"
PHOTO_INIT="intel"

if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    JELLYFIN_FILE="docker-compose.jellyfin.nvidia.yml"
    PHOTO_FILE="docker-compose.photo.nvidia.yml"
    echo "--> 探测到 NVIDIA 独显驱动正常，启用 NVIDIA 硬件加速组件"
elif [ -e /dev/dri/renderD128 ]; then
    JELLYFIN_FILE="docker-compose.jellyfin.dri.yml"
    PHOTO_FILE="docker-compose.photo.dri.yml"
    echo "--> 探测到 Linux DRI 设备 (/dev/dri/renderD128)，启用 DRI 硬件加速组件"
    if grep -qi "amd" /proc/cpuinfo 2>/dev/null; then
        PHOTO_ENC="vulkan"
        PHOTO_INIT="vulkan"
        echo "--> 探测到 AMD 平台，PhotoPrism 转码器配置为: vulkan"
    else
        PHOTO_ENC="intel"
        PHOTO_INIT="intel"
        echo "--> 探测到 Intel 平台，PhotoPrism 转码器配置为: intel (QuickSync)"
    fi
else
    JELLYFIN_FILE="docker-compose.jellyfin.dri.yml"
    PHOTO_FILE="docker-compose.photo.dri.yml"
    echo "--> 未检测到独立硬件加速设备，启用默认组件"
    PHOTO_ENC="software"
    PHOTO_INIT="software"
fi

# 3. 更新或写入到 .env
update_env_var() {
    local key="$1"
    local val="$2"
    if grep -q "^${key}=" "$ENV_FILE"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
        echo "${key}=${val}" >> "$ENV_FILE"
    fi
}

# 清理旧的遗留变量
sed -i '/^COMPOSE_PROFILES=/d' "$ENV_FILE" 2>/dev/null || true
sed -i '/^COMPOSE_FILE=/d' "$ENV_FILE" 2>/dev/null || true

update_env_var "JELLYFIN_COMPOSE" "$JELLYFIN_FILE"
update_env_var "PHOTO_COMPOSE" "$PHOTO_FILE"
update_env_var "RENDER_GID" "$RENDER_GID"
update_env_var "VIDEO_GID" "$VIDEO_GID"
update_env_var "PHOTO_ENCODER" "$PHOTO_ENC"
update_env_var "PHOTO_INIT" "$PHOTO_INIT"

echo "✅ 配置已成功写入 ${ENV_FILE}:"
grep -E '^(JELLYFIN_COMPOSE|PHOTO_COMPOSE|RENDER_GID|VIDEO_GID|PHOTO_ENCODER|PHOTO_INIT)=' "$ENV_FILE"
echo ""
echo "现在可直接执行: docker-compose up -d 启动服务！"

