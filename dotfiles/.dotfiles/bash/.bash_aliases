### .bash_aliases
### by Cashiuus          (Updated: 2020-11-11)
###
### ------------------------------------------ ###

alias bashload="source ${HOME}/.bashrc"
alias update-kali="apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade"
alias cls='clear'
alias open="gedit"
alias path='echo $PATH | tr -s ":" "\n"'

### Custom Folder Workflows
alias d="cd ~/Documents"
alias dl="cd ~/Downloads"
alias drop="cd ~/dropbox"
alias e="cd ~/Engagements"
alias g="cd ${HOME}/git"
alias p="cd /opt/pentest"


### Networking
alias myip='curl ifconfig.me; echo'
# Sorts IPs; ex: cat "ips.txt | ip_sort"
alias ip_sort='sort -u -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n'
alias sip='sort -V'
if [[ $(which netstat) ]]; then
    alias openports='netstat --all --numeric --programs --inet' # or netstat -planta
elif [[ $(which ss) ]]; then
    alias openports='ss -tunlp'
fi
#alias lsof='lsof -nP -iTCP -sTCP:LISTEN'
alias ping='ping -c 3'
alias webserv='python3 -m http.server'
alias webserver='python3 -m http.server'
alias header="curl -I"
dns=$(grep 'nameserver' /etc/resolv.conf | awk '{print $2}')
if [[ `id -u` -eq 0 ]]; then
    # Checking if root first, else these cmds fail under a regular
    # user every time they open a terminal window.
    interface=$(ifconfig | grep -B1 'inet addr' | egrep -v '(-|inet addr|Loopback)' | cut -d ' ' -f1)
    ip=$(ifconfig | grep 'Bcast' | awk '{print$2}' | cut -d ':' -f2)
    mac=$(ifconfig | grep -B1 'inet addr' | egrep -v '(-|inet addr|Loopback)' | awk '{print$5}')
fi

alias n='echo ; netstat -antup | egrep -v "Active" ; echo ;
echo -n "Interface:    "$interface ; echo ;
echo -n "MAC address:  "$mac ; echo ;
echo -n "Internal IP:  "$ip ; echo ;
echo -n "External IP:  " ; curl ifconfig.me ; echo'


### Application Shortcuts
alias axel="axel -a"
# Show 3 months by default for calendar
alias cal='cal -3'
alias chrome='/opt/google/chrome/chrome'
alias lynx='lynx -force_html -width=$COLUMNS' #best settings for viewing HTML
alias links='links -force-html' #need to enable colour in config menu manually
alias strings="strings -a"

alias screen="screen -xRR"
# Disabling as this causes issues with all attempts at running normal tmux commands
#alias tmux="tmux attach || tmux new"

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

### Security Tool Enhancements
alias nexpose='service postgresql stop ; cd /opt/rapid7/nexpose/nsc ; ./nsc.sh'
alias nmap="nmap --reason --open"
function nse(){ find /usr/share/nmap/scripts/ -iname "*$1*" -printf '%P\n';}
alias aircrack-ng="aircrack-ng -z"
alias airodump-ng="airodump-ng --manufacturer --wps --uptime"
### Metasploit
alias msfc="systemctl start postgresql; msfdb start; msfconsole -q \"$@\""
alias msfconsole="systemctl start postgresql; msfdb start; msfconsole -q \"$@\""
alias openvas="openvas-stop; openvas-start; sleep 3s; xdg-open https://127.0.0.1:9392/ >/dev/null 2>&1"
alias mana-toolkit-start="a2ensite 000-mana-toolkit;a2dissite 000-default;systemctl apache2 restart"
alias mana-toolkit-stop="a2dissite 000-mana-toolkit;a2ensite 000-default;systemctl apache2 restart"

### Git: Spelling Error Variants
alias got='git '
alias get='git '

### Git Custom Commands
alias git-owner="cat .git/config | grep 'url' || echo 'You do not appear to be in a git repo folder'"

# Ref: http://stackoverflow.com/questions/39797471/git-clone-all-branches-bash-script-as-git-alias/39797536
# Create an alias that runs a script
alias git-clone-all-branches=$(git config --global alias.clone-all-branches '!git branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -L1 git checkout -t')
# The script: git config --global alias.clone-all-branches '!git branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -L1 git checkout -t'
# NOTE: Must prefix git with '!' if it's not a subcommand for this alias command as per the link's comments

### Checksums
alias sha1="openssl sha1"
alias md5="openssl md5"

### Folder Creation
alias mkdir="/bin/mkdir -pv"

alias ..="cd .."
alias ...="cd ../.."
alias cdup="cd .."

### CLI Navigation
alias more='less'
alias head='head -n $((${LINES:-12}-2))' #as many as possible without scrolling
alias tail='tail -n $((${LINES:-12}-2)) -s.1' #Likewise, also more responsive -f

### Colorizing
alias grep="grep --color=auto -I" #ignore binary files when searching inside
alias ngrep="ngrep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto -I"

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
    colorflag="--color"
else # OS X `ls`
    colorflag="-G"
fi

# Always use color output for `ls`
alias ls="command ls -Ahp ${colorflag}"
alias l="ls -alF ${colorflag}"
alias ll="ls -al"
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'

# Always print human-readable for various disk space commands
alias df='df -h'
alias free='free -h'
alias diskfree='du -s -h'
alias diskfree-var='du -h --all --max-depth=1 /var 2>/dev/null'

# Setup SUDO action for non-root usage
if [ $UID -ne 0 ]; then
    alias s='sudo '
    alias scat='sudo cat'
    alias stail='sudo tail'
    alias root='sudo su'
    alias reboot='sudo reboot'
    alias halt='sudo halt'
fi

