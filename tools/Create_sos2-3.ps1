# Make a copy of the directory containing previous version of sos2 and name it sos2-3
Copy-Item ./sos2-2 ./sos2-3 -Recurse

Set-Location ./sos2-3

if (Test-Path -Path "./.git") {
    # Supprimer le répertoire .git
    Remove-Item ./.git -Recurse -Force
} 

if (Test-Path -Path "./download") {
    # Clean up ./download
    Get-ChildItem .\download\ | Remove-Item -Recurse -Force
}else{
    New-Item ./download -ItemType Directory
}

# Get a copy of the article 2 and article 3
Invoke-WebRequest -URI http://sos.enix.org/wiki-fr/upload/SOSDownload/sos-code-art2.tgz -OutFile ./download/sos-code-art2.tgz
tar -xvzf ./download/sos-code-art2.tgz -C ./download

Invoke-WebRequest -URI http://sos.enix.org/wiki-fr/upload/SOSDownload/sos-code-art3-lm64.tgz -OutFile ./download/sos-code-art3-lm64.tgz
tar -xvzf ./download/sos-code-art3-lm64.tgz -C ./download

# Compare both directories and display differences
$Directories = Get-ChildItem .\download\sos-code-article3\ -Directory
foreach ( $Directory in $Directories) {
    $Name = Split-Path -Path $Directory -Leaf
    $Prev_Ver = Get-ChildItem -Recurse -Path .\download\sos-code-article2\$Name
    $New_Ver = Get-ChildItem -Recurse -Path .\download\sos-code-article3\$Name
    # Compare-Object $Prev_Ver $New_Ver -Property Name, Length -IncludeEqual
    Compare-Object $Prev_Ver $New_Ver -Property Name, Length 
}

# Replace the current ./hwcore with the one coming from article2
# Copy-Item ./download/sos-code-article2/hwcore ./ -Recurse -Force

# update main.c and types.h with version from article 2
Copy-Item ./download/sos-code-article3/sos/errno.h ./sos/errno.h
Copy-Item ./download/sos-code-article3/sos/list.h ./sos/list.h
Copy-Item ./download/sos-code-article3/sos/macros.h ./sos/macros.h
Copy-Item ./download/sos-code-article3/sos/main.c ./sos/main.c
Copy-Item ./download/sos-code-article3/sos/physmem.c ./sos/physmem.c
Copy-Item ./download/sos-code-article3/sos/physmem.h ./sos/physmem.h
Copy-Item ./download/sos-code-article3/sos/types.h ./sos/types.h

# Copy Create_sos2-2.ps1 in ./tools/Create_sos2-2.ps1
Copy-Item ../Create_sos2-3.ps1 ./tools/Create_sos2-3.ps1
# Remove-Item ../Create_sos2-3.ps1

# Launch VSCode from the current dir
# code .