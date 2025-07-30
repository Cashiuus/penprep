#!/bin/bash

# This will output all of the available color choices we can use in terminal scripts



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


echo -e "${GREEN}This is the color for GREEN${RESET}"
echo -e "${YELLOW}This is the color YELLOW${RESET}"
echo -e "${RED}This is the color RED${RESET}"
echo -e "${BLUE}This is the color for BLUE${RESET}"
echo -e "${PURPLE}This is the color for PURPLE${RESET}"
echo -e "${GREY}This is the color GREY${RESET}"
echo -e "${BOLD}This is the color BOLD${RESET}"
echo -e "${BGRED}This is the color for BGRED${RESET}"
echo -e "${BGPURPLE}This is the color for BGPURPLE${RESET}"
echo -e "${BGYELLOW}This is the color for BGYELLOW${RESET}"
echo -e "${BGBLUE}This is the color for BGBLUE${RESET}"


for i in {30..47}; do
    echo -e "\e[1;${i}m" "Showing Range of Colors for: $i${RESET}"
done


exit 0




color=(
# Text color codes:
  30 black                  40 bg-black
  31 red                    41 bg-red
  32 green                  42 bg-green
  33 yellow                 43 bg-yellow
  34 blue                   44 bg-blue
  35 magenta                45 bg-magenta
  36 cyan                   46 bg-cyan
  37 white                  47 bg-white
)
#local k
#for k in ${(k)color}; do color[${color[$k]}]=$k; done




