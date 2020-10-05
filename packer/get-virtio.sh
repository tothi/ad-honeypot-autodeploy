#!/bin/bash
#

echo "[*] Cleaning up & init virtio folder..."
rm -fr virtio
mkdir virtio
if ! cd virtio; then
    echo "[!] Problem creating virtio folder"
    exit 0
fi

echo "[*] Downloading stable virtio-win.iso..."
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

echo "[*] Extracting iso..."
mkdir virtio-win
7z x -ovirtio-win virtio-win.iso

echo "[*] Arranging drivers..."
shopt -s nullglob
for winver in w10 w8.1 2k16; do
  mkdir -p ${winver}/core
  mkdir -p ${winver}/extra
  for driver in NetKVM viostor; do
    for f in virtio-win/${driver}/${winver}/amd64/*.{inf,cat,sys,dll}; do
      mv $f ${winver}/core
    done
  done
  for driver in Balloon viorng vioserial qxldod; do
    for f in virtio-win/${driver}/${winver}/amd64/*.{inf,cat,sys,dll}; do
      mv $f ${winver}/extra
    done
  done
done
shopt -u nullglob

echo "[*] Cleaning up..."
rm -fr virtio-win

