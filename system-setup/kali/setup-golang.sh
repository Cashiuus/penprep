



### Install the "Go" programming language kit
# Ref: https://golang.org/doc/install
# https://golang.org/dl/

# Version: 1.10.3


cd ~/Downloads
#https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
wget -c https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
tar -C /usr/local -xvzf go1.10.3.linux-amd64.tar.gz

mkdir -p ~/go_projects/{bin,src,pkg}

# Add Go to our PATH env var into /etc/profile or ~/.bash_profile
    # Go lang
    export PATH=\$PATH:/usr/local/go/bin

    # user workspace directories
    export GOPATH="\$HOME/go_projects"
    export GOBIN="\$GOPATH/bin"


# *NOTE: If you install Go in another directory from /usr/local, you must also
#        specify GOROOT variable - e.g.: export GOROOT=$HOME/go
#                                        export PATH=$PATH:$GOROOT/bin


# Verify Go installation
go version
go env
#go help


# Install a project using go
# cd ~/git && go get github.com/subfinder/subfinder
# or upgrade existing: go get -u github.com/subfinder/subfinder
