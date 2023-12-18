New-Item sos2 -ItemType Directory
Set-Location sos2
New-Item download -ItemType Directory
Invoke-WebRequest -URI http://sos.enix.org/wiki-fr/upload/SOSDownload/sos-code-art1.tgz -OutFile ./download/sos-code-art1.tgz

tar -xvzf ./download/sos-code-art1.tgz -C ./download

New-Item build -ItemType Directory
New-Item buildenv -ItemType Directory
New-Item target/iso/boot/grub -ItemType Directory

Copy-Item ./download/sos-code-article1/bootstrap ./bootstrap -Recurse
Copy-Item ./download/sos-code-article1/drivers ./drivers -Recurse
Copy-Item ./download/sos-code-article1/hwcore ./hwcore -Recurse
Copy-Item ./download/sos-code-article1/sos ./sos -Recurse

"dist/
build/" | Out-File -FilePath ./.gitignore.txt -Encoding ascii


