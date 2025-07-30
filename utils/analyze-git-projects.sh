#!/usr/bin/env bash
## =============================================================================
# File:     analyze-git-projects.sh
# Author:   Cashiuus
# Created:  24-Nov-2020     Revised: 18-Nov-2022
#
##-[ Info ]---------------------------------------------------------------------
# Purpose:  Recursively analyze a path for all git repo's, their state, and
#           try to list all files that exist but are .gitignore'd and you
#           may need to manually back them up or copy off to avoid losing them.
#
#
##-[ Links/Credit ]-------------------------------------------------------------
# - Ref: https://unix.stackexchange.com/questions/323433/list-files-not-stored-in-git-repos
#
##-[ Copyright ]----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =============================================================================
__version__="0.0.1"
__author__="Cashiuus"
## ==========[  TEXT COLORS  ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
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
## =============[  CONSTANTS  ]============= ##
TDATE=$(date +%Y-%m-%d)



if [[ -d "$1" ]]; then
    D=$(find ${1} -name '.git' -exec dirname {} \;)
else
    D=$(find ${HOME} -name '.git' -exec dirname {} \;)
fi



echo -e "\n\n[*] Checking Git Projects for locally modified files to backup"

# Testing a way to check all file patterns in one loop
for g in $(find $D -name .git); do
    p=${g%/.git}
    g2=`readlink -f $g`
    git_project_dir=`readlink -f $p`
    echo -e "\n\n[*] Checking git project: {git_project_dir}"
    echo -e "Project Remotes:"
    ( cd $p && GIT_DIR=$g2 git remote -v )
    #echo -e "\nChanged Files:"
    #( cd $p && GIT_DIR=$g2 git ls-files --modified --others --full-name )
    #--exclude="debug.log"
    echo -e "\n\nCurrent 'git status' Including Untracked or Ignored Files:"
    #git ls-files --others --exclude-standard
    ( cd $p && git status -v --porcelain --ignored --untracked-files=all )
    # use --full-name to get full file path from project root in results instead of local relative to curdir
    echo -e "------------------------------------------"
done > "${HOME}/git-review-list_${TDATE}.txt"
exit 0





# Find all git projects, and
# 1. list files that are in repo but were modified locally
for g in $(find $D -name .git); do
    echo -e "[*] Checking $g"
    p=${g%/.git} g2=`readlink -f $g` ;
    ( cd $p && GIT_DIR=$g2 \
        git ls-files --full-name ) | sed "s,^,${p}/,g" ;
done > git-review-list-1




# Find all git projects, and
# 2. list ignored files (those matching a pattern in gitignore)
for g in $(find $D -name .git) ; do
    p=${g%/.git} g2=`readlink -f $g` ;
    ( cd $p && GIT_DIR=$g2 \
        git ls-files --others -i --exclude-standard ) | sed "s,^,${p}/,g" ;
done > git-review-list-2



# Find all git projects, and
# 2. list ignored files (those matching a pattern in gitignore)
for g in $(find $D -name .git) ; do
    p=${g%/.git} g2=`readlink -f $g` ;
    ( cd $p && GIT_DIR=$g2 git ls-files --others )
done > git-review-list-3



# Other options

# For scripting, these are superior means:
# git status --porcelain
# git diff-files --name-status

# git status --short
# git diff --name-status


# git read-tree ?

