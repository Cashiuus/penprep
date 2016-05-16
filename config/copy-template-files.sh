#!/bin/bash


# Run script daily to keep template files current in git repo(s)



DIR1="${HOME}/.config/geany/templates/files"
DEST="${HOME}/git/penprep/kali/templates"

find "${DIR1}" -type f | while read item; do echo "Copying: ${item}"; cp -u ${item} "${DEST}/"; done
