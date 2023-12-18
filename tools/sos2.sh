#!/usr/bin/env bash

mkdir ./sos2
cd ./sos2

mkdir ./download
wget -P ./download http://sos.enix.org/wiki-fr/upload/SOSDownload/sos-code-art1.tgz 
tar -xvzf ./download/sos-code-art1.tgz -C ./download

mkdir ./build
mkdir ./buildenv
mkdir -p ./target/iso/boot/grub

cp -r ./download/sos-code-article1/bootstrap ./bootstrap 
cp -r ./download/sos-code-article1/drivers ./drivers 
cp -r ./download/sos-code-article1/hwcore ./hwcore 
cp -r ./download/sos-code-article1/sos ./sos 

echo "dist/
build/" > .gitignore
