#!/bin/bash


# ===[ vFeed ]=== #

function vfeed_helper_update(INSTALL_PATH) {
    if [[ ! -x /usr/local/bin/vfeed_update ]]; then
        file="/usr/local/bin/vfeed_update"
        cat <<EOF > "${file}"
#!/bin/bash

cd ${INSTALL_PATH}
if [[ -d '.git' ]]; then
    echo -e '[*] vFeed appears installed. Now updating to latest..."
    git checkout master && git pull origin master
fi
python vfeedcli.py --update
EOF
        chmod +x "${file}"
    fi
}


function vfeed_helper_cli(INSTALL_PATH) {
    if [[ ! -x /usr/local/bin/vfeedcli ]]; then
        file="/usr/local/bin/vfeedcli"
        cat <<EOF > "${file}"
#!/bin/bash

cd ${INSTALL_PATH} && python vfeedcli.py "\$@"
EOF
        chmod +x "${file}"
        #ln -s "${file}" /usr/local/bin/vfeedcli
    fi
}


function vfeed_install(INSTALL_PATH) {
    [[ ! -d "${INSTALL_PATH}" ]] && mkdir -p "${INSTALL_PATH}"
    cd "${INSTALL_PATH}"
    if [[ ! -d "${INSTALL_PATH}/vfeed" ]]; then
        git clone https://github.com/toolswatch/vfeed
        cd vfeed
        # DevAlias' scripts are outdated and rely on hardcoded install path
        #git clone https://gist.github.com/7554985.git bin
        [[ ! -d "bin" ]] && mkdir "bin"
        cd bin
        #chmod +x vfeed*.sh
        # Creating our own update file, pointing to vfeed install path
        vfeed_helper_update "${INSTALL_PATH}/vfeed"
        vfeed_helper_cli "${INSTALL_PATH}/vfeed"
    else
        # Run helper check first just in case
        vfeed_helper_update "${INSTALL_PATH}/vfeed"
        /usr/local/bin/vfeed_update
    fi
}

