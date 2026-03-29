#!/bin/bash
# 通用 qcow2 扩容脚本（针对 Aliyun TD 镜像）
# 用法: resize_image.sh <IMAGE_PATH> [NEW_SIZE_GB]
#   IMAGE_PATH    : 镜像路径，支持相对路径与绝对路径；须显式指定。
#   NEW_SIZE_GB  : 目标大小（单位：GB），可选；未传入时默认 500G。

set -e

# ===== 可配置参数 =====
# 镜像路径（第一个参数；相对路径相对于当前工作目录）
IMAGE_PATH="${1:-}"
# 目标大小（单位：GB）（第二个参数；未传入时默认 500）
NEW_SIZE_GB="${2:-500}"
# ======================

usage() {
  echo "Usage: $0 <IMAGE_PATH> [NEW_SIZE_GB]" >&2
  echo "  IMAGE_PATH    qcow2 镜像路径（相对或绝对）；必须指定。" >&2
  echo "  NEW_SIZE_GB   目标大小（单位：GB）；可选；默认 500。" >&2
  exit 1
}

if [ -z "${IMAGE_PATH}" ]; then
  echo "Error: IMAGE_PATH is required." >&2
  usage
fi

if ! [[ "${NEW_SIZE_GB}" =~ ^[0-9]+$ ]]; then
  echo "Error: NEW_SIZE_GB must be an integer (GB), got: ${NEW_SIZE_GB}" >&2
  usage
fi

echo "Image path : ${IMAGE_PATH}"
echo "Target size: ${NEW_SIZE_GB}G"

if [ ! -f "${IMAGE_PATH}" ]; then
  echo "Error: image not found: ${IMAGE_PATH}"
  exit 1
fi

echo
echo "Current image info:"
qemu-img info "${IMAGE_PATH}" || true

echo
echo "Resizing to ${NEW_SIZE_GB}G..."
qemu-img resize "${IMAGE_PATH}" "${NEW_SIZE_GB}G"

echo
echo "New image info:"
qemu-img info "${IMAGE_PATH}"

echo
echo "Done. 注意：在虚机内部还需要扩容分区和文件系统（growpart/resize2fs 等）。"
