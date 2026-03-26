#!/bin/bash

modprobe vfio
modprobe vfio-pci
# 自动获取 NVIDIA GPU 设备列表 (3D controller)
GPUS=($(lspci -nn | grep -i nvidia | grep "3D controller" | awk '{print $1}'))

# 自动获取 NVSwitch 设备列表 (Bridge)
NVSWITCHS=($(lspci -nn | grep -i nvidia | grep "Bridge" | awk '{print $1}'))

if [ ${#GPUS[@]} -eq 0 ]; then
    echo "Error: No NVIDIA GPU found!"
    exit 1
fi

echo "Detected GPUs: ${GPUS[@]}"
echo "Detected NVSwitchs: ${NVSWITCHS[@]}"

# 获取 Device ID（使用第一个 GPU）
DEV_ID=$(lspci -nn -s ${GPUS[0]} | grep -oP '\[10de:\K[0-9a-f]+')
echo "Detected NVIDIA Device ID: $DEV_ID"

# 解绑 nvidia 并绑定 vfio-pci
for gpu in "${GPUS[@]}"; do
    echo "Binding $gpu to vfio-pci..."
    echo "$gpu" | sudo tee /sys/bus/pci/devices/$gpu/driver/unbind 2>/dev/null
    echo "vfio-pci" | sudo tee /sys/bus/pci/devices/$gpu/driver_override
    echo "$gpu" | sudo tee /sys/bus/pci/drivers/vfio-pci/bind
done

for nvswitch in "${NVSWITCHS[@]}"; do
    echo "Binding NVSwitch $nvswitch to vfio-pci..."
    echo "$nvswitch" | sudo tee /sys/bus/pci/devices/$nvswitch/driver/unbind 2>/dev/null
    echo "vfio-pci" | sudo tee /sys/bus/pci/devices/$nvswitch/driver_override
    echo "$nvswitch" | sudo tee /sys/bus/pci/drivers/vfio-pci/bind
done

# 注册 ID
echo "10de $DEV_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id

# 验证
echo "Checking vfio-dev directories..."
for gpu in "${GPUS[@]}"; do
    ls /sys/bus/pci/devices/$gpu/vfio-dev 2>/dev/null && echo "$gpu: OK" || echo "$gpu: FAILED"
done
for nvswitch in "${NVSWITCHS[@]}"; do
    ls /sys/bus/pci/devices/$nvswitch/vfio-dev 2>/dev/null && echo "$nvswitch: OK" || echo "$nvswitch: FAILED"
done
