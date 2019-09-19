#!/bin/sh
set -euf
cd "$(dirname "${0}")"

output="${HOME}/.bin"
if [ -d "${output}" ]; then
    rm -rf "${output}"
fi
mkdir "${output}"

install() {
    cp "${1}.sh" "${output}/${1}"
    chmod a+x "${output}/${1}"
}

install 'cldir'