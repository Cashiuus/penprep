#!/usr/bin/env bash
## =======================================================================================
# File:     setup-git.sh
# Author:   Cashiuus
# Created:  16-Dec-2021     Revised:
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.0.1"
__author__="Cashiuus"
## ==========[  TEXT COLORS  ]============= ##
RESET="\033[00m"        # Normal
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings (some terminals its yellow)
RED="\033[01;31m"       # Errors
BLUE="\033[01;34m"      # Headings
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Normal fg color, but bold
ORANGE="\033[38;5;208m" # Debugging
BGRED="\033[41m"        # BG Red
BGPURPLE="\033[45m"     # BG Purple
BGYELLOW="\033[43m"     # BG Yellow
BGBLUE="\033[104m"      # White font with blue background (could also use 44)
## =============[ CONSTANTS ]============= ##

GIT_MAIN_DIR="${HOME}/git"
GIT_DEV_DIR="${HOME}/git-dev"


function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
      echo -e "${YELLOW}[WARN] This script leverages sudo for installation. Enter your password when prompted!${RESET}"
      sleep 1
      # Test to ensure this user is able to use sudo
      sudo -l >/dev/null
      if [[ $? -eq 1 ]]; then
        # sudo pkg is installed but current user is not in sudoers group to use it
        echo -e "${RED}[ERROR]${RESET} You are not able to use sudo. Running install to fix."
        read -r -t 5
        install_sudo
      fi
    else
        echo -e "${RED}[ERROR]${RESET} Can't use sudo, fix your system and try again!"
        exit 1
    fi
  fi
}
check_root


##  Check Internet Connection
echo -e "${GREEN}[*]${RESET} Checking Internet access"
for i in {1..4}; do ping -c 1 -W ${i} google.com &>/dev/null && break; done
if [[ "$?" -ne 0 ]]; then
  for i in {1..4}; do ping -c 1 -W ${i} 8.8.8.8 &/dev/null && break; done
  if [[ "$?" -eq 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} Internet partially working, DNS is failing, check resolv.conf"
    exit 1
  else
    echo -e "${RED}[ERROR]${RESET} Internet is completely down, check IP config or router"
    exit 1
  fi
fi


## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

$SUDO apt-get -qq update
$SUDO apt-get -y install git


[[ ! -d "${GIT_MAIN_DIR}" ]] && mkdir -p "${GIT_MAIN_DIR}" 2>/dev/null
[[ ! -d "${GIT_DEV_DIR}" ]] && mkdir -p "${GIT_DEV_DIR}" 2>/dev/null


# ==========[ Configure GIT ]=========== #
echo -e "${GREEN}[+]${RESET} Now setting up Git, you will be prompted to enter your name for commit author info..."
# -== Git global config settings ==- #
echo -e -n "  Git global config :: Enter your name: "
read GIT_NAME
git config --global user.name "$GIT_NAME"
echo -e -n "  Git global config :: Enter your email: "
read GIT_EMAIL
git config --global user.email "$GIT_EMAIL"
git config --global color.ui auto

echo -e "${GREEN}[*]${RESET} As of Oct 1, 2020, Git has changed default branch to 'main'"
echo -e "${GREEN}[*]${RESET} Therefore, setting your git config default branch to 'main' now"
git config --global init.defaultBranch main
# Set the previously-default setting to suppress warnings and make this the new default
git config --global pull.rebase false

# Git Aliases Ref: https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
# Other settings/standard alias helpers
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
# Git short status
git config --global alias.s 'status -s'

# Create custom unstage alias - Type: git unstage fileA (same as: git reset HEAD -- fileA)
git config --global alias.unstage 'reset HEAD --'

# Show the last commit (Type: git last)
git config --global alias.last 'log -1 HEAD'

# My Custom Git Aliases
# TODO: Test if this works correctly, it should simply add --recursive to every clone
# The reason for --recursive is for git projects with submodules, which don't clone by default
#git config --global alias.clone 'clone --recursive'

# Other alias ideas:
#   https://majewsky.wordpress.com/2010/11/29/tip-of-the-day-dont-remember-git-clone-urls/





# ========[ SSH Key Integrations ] ======== #

# If you need to create a new SSH key, you can do it via:
#ssh-keygen -t rsa -C "<your_email>" -f ~/.ssh/<key_filename>
# To change your pw/passphrase on an existing ssh key, do that via:
#ssh-keygen -p -f ~/.ssh/<your_key>
echo -e "${GREEN}[*]${RESET} Listing your .ssh directory contents for the next input request"
ls -al "${HOME}/.ssh/"
echo -e "\n"
#echo -e -n "${YELLOW}[INPUT]${RESET} Git :: Enter your current Github SSH Key full file path: "
#read GIT_SSH_KEY

found=false
while [[ ! $finished ]]; do
    read -r -e -p "  Please enter your current Github SSH key absolute file path: " GIT_SSH_KEY
    if test -e "${GIT_SSH_KEY}"; then
        finished=true
        break
    else
        echo -e "${YELLOW}[-]${RESET} Provided file path is invalid, try again!\n"
    fi
done

echo -e "${ORANGE}[DEBUG] GIT_SSH_KEY is: $GIT_SSH_KEY ${RESET}"
if [[ -e "${GIT_SSH_KEY}" ]]; then
    # Ensure it has the right permissions
    chmod 0400 "${GIT_SSH_KEY}"
    ssh-agent -s || $(eval ssh-agent)
    ssh-add "${GIT_SSH_KEY}" || echo -e "${RED}[ERROR]${RESET} Failed to add SSH key to ssh-agent, add it manually later."
    file="${HOME}/.ssh/config"
    if [[ ! -e "${file}" ]]; then
        cat <<EOF > "${file}"
Host github
    Hostname github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ${GIT_SSH_KEY}

Host gitlab
    Hostname gitlab.com
    User git
    PreferredAuthentications publickey
    IdentityFile ${GIT_SSH_KEY}

# Place additional host aliases here, such as for work if it uses a different key
# Usage: git clone git@github_work:user/repo.git
#Host github_work
#       User git
#       PreferredAuthentications publickey
#       IdentityFile ~/.ssh/work_key

EOF
        # Test the connection
        echo -e "${GREEN}[*]${RESET} Testing your git connection..."
        ssh -T git@github
    else
        echo -e "${YELLOW}[WARN]${RESET} File ~/.ssh/config already exists! Fix it manually!"
    fi
else
    echo -e "${YELLOW}[WARN]${RESET} SSH Key provided is not a valid file, so fix and try again!"
    exit 1
fi



# ==========[ Add GIT Files ]=========== #
file="${HOME}/.gitexcludes"
if [[ ! -f "${file}" ]]; then
    cat <<EOF > "${file}"
# Octocat Recommendations: https://gist.github.com/octocat/9257657
# Git gitignore Manual: http://git-scm.com/docs/gitignore
# gitignore Example Files: https://github.com/github/gitignore

# This can also be a .gitignore_global file I believe

# === OS X ===
.DS_Store
.Spotlight-V100
.Trashes

# === DB Files ===
*.sqlite3

# === VI Swap Files ===
.swp

# === Misc ===
*.cap
*.local
*.log
*.ovpn
*.pyc

EOF
fi



# ====[ Configure SSH-agent to run automatically ]=== #
# Reference: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases
file="${HOME}/.sshagent"
cat <<EOF > "${file}"
#
#
# Note: ~/.ssh/environment should not be used, as it
#       already has a different purpose in SSH.

env="${HOME}/.ssh/agent.env"

# Note: Don't bother checking SSH_AGENT_PID. It's not used
#       by SSH itself, and it might even be incorrect
#       (for example, when using agent-forwarding over SSH).

agent_is_running() {
    if [ "$SSH_AUTH_SOCK" ]; then
        # ssh-add returns:
        #   0 = agent running, has keys
        #   1 = agent running, no keys
        #   2 = agent not running
        ssh-add -l >/dev/null 2>&1 || [ $? -eq 1 ]
    else
        false
    fi
}

agent_has_keys() {
    ssh-add -l >/dev/null 2>&1
}

agent_load_env() {
    . "${env}" >/dev/null
}

agent_start() {
    (umask 077; ssh-agent >"$env")
    . "$env" >/dev/null
}

if ! agent_is_running; then
    agent_load_env
fi

# if your keys are not stored in ~/.ssh/id_rsa.pub or ~/.ssh/id_dsa.pub, you'll need
# to paste the proper path after ssh-add
if ! agent_is_running; then
    agent_start
    ssh-add
elif ! agent_has_keys; then
    ssh-add
fi

unset env

EOF


# Determine user's active shell to update the correct resource file
if [[ "${SHELL}" == "/usr/bin/zsh" ]]; then
    SHELL_FILE=~/.zshrc
elif [[ "${SHELL}" == "/bin/bash" ]]; then
    SHELL_FILE=~/.bashrc
else
    # Just in case I add other shells in the future
    SHELL_FILE=~/.bashrc
fi

# Add source for .sshagent file so it loads for each new session
grep -q 'source "${HOME}/.dotfiles/bash/.bash_sshagent' "${SHELL_FILE}" \
    || echo '[[ -s "${HOME}/.sshagent" ]] && source "${HOME}/.sshagent"' >> "${SHELL_FILE}"








# -- Finished - Script End -----------------------------------------------------
function ctrl_c() {
  # Capture pressing CTRL+C during script execution to exit gracefully
  #     Usage:     trap ctrl_c INT
  echo -e "${GREEN}[*] ${RESET}CTRL+C was pressed -- Shutting down..."
  trap finish EXIT
}


# -- Git Setup Notes -----------------------------------------------------------
#
# How to change existing repo's from http to ssh
#       cd ~/git/dir
#       git remote -v
#       git remote set-url origin git@github.com:<forked_user>/<forked_repo>
#       git remote set-url upstream git@github.com:<orig_user>/<orig_repo>
#       git remote -v
#       git pull
#
#
