#!/bin/bash

# =========================================================
#  CYRECON — Cyber Reconnaissance Framework
#  Author: Odejide Femisola Francis (Cyphem)
#  Automated subdomain / liveness / URL reconnaissance
# =========================================================

# ---------------- DEPENDENCY MANAGEMENT ---------------- #

# Tools installed via the system package manager
REQUIRED_APT_TOOLS=(curl jq)

# Tools installed via Go (module path used for `go install`)
declare -A GO_TOOL_PATHS=(
  [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  [assetfinder]="github.com/tomnomnom/assetfinder@latest"
  [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
  [waybackurls]="github.com/tomnomnom/waybackurls@latest"
)

# Run a privileged command only if not already root
run_priv() {
  if [ "$EUID" -ne 0 ] && command -v sudo &> /dev/null; then
    sudo "$@"
  else
    "$@"
  fi
}

# Install a system package, picking the right manager (Termux vs Debian/Kali)
install_system_pkg() {
  local pkg="$1"
  if command -v pkg &> /dev/null; then
    pkg install -y "$pkg"
  elif command -v apt-get &> /dev/null; then
    run_priv apt-get update -y
    run_priv apt-get install -y "$pkg"
  else
    echo -e "\e[1;31m[!] No supported package manager found. Install '$pkg' manually.\e[0m"
    return 1
  fi
}

# Make sure Go's bin directory is on PATH for this session and future ones
ensure_go_path() {
  local gobin
  gobin="$(go env GOPATH 2>/dev/null)/bin"
  [ -z "$gobin" ] && gobin="$HOME/go/bin"

  export PATH="$PATH:$gobin"

  local rc_file="$HOME/.bashrc"
  [ -n "$ZSH_VERSION" ] && rc_file="$HOME/.zshrc"

  if [ -f "$rc_file" ] && ! grep -q "$gobin" "$rc_file"; then
    echo "export PATH=\$PATH:$gobin" >> "$rc_file"
    echo -e "\e[1;33m[+] Added $gobin to PATH in $rc_file (restart your shell or 'source $rc_file')\e[0m"
  fi
}

# Check every dependency and install whatever is missing
check_and_install_dependencies() {
  echo -e "\e[1;36m[*] Checking required tools...\e[0m"

  # Go toolchain itself, needed to install the Go-based recon tools
  if ! command -v go &> /dev/null; then
    echo -e "\e[1;33m[!] Go not found. Installing Go...\e[0m"
    if command -v pkg &> /dev/null; then
      install_system_pkg golang
    else
      install_system_pkg golang-go
    fi
  fi

  ensure_go_path

  # System packages
  for tool in "${REQUIRED_APT_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo -e "\e[1;33m[!] $tool not found. Installing...\e[0m"
      install_system_pkg "$tool"
    else
      echo -e "\e[1;32m[+] $tool already installed\e[0m"
    fi
  done

  # Go-based recon tools
  for tool in "${!GO_TOOL_PATHS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo -e "\e[1;33m[!] $tool not found. Installing via go install...\e[0m"
      go install "${GO_TOOL_PATHS[$tool]}"
    else
      echo -e "\e[1;32m[+] $tool already installed\e[0m"
    fi
  done

  echo -e "\e[1;36m[*] Dependency check complete.\e[0m"
  echo
}

# ---------------- BANNER ---------------- #

clear
echo -e "\e[1;36m"
cat << "EOF"

 ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗
██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║
██║      ╚████╔╝ ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║
██║       ╚██╔╝  ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║
╚██████╗   ██║   ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
 ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝

        🔍 CYBER RECONNAISSANCE FRAMEWORK 🔍
           Domain • Liveness • URL Checking
           BY: Odejide Femisola Francis

EOF
echo -e "\e[0m"

# Run the dependency check automatically on every launch
check_and_install_dependencies

# ---------------- USAGE MENU ---------------- #

echo -e "\e[1;33mSelect an option:\e[0m"
echo -e "\e[1;32m[1]\e[0m Subdomain Enumeration"
echo -e "\e[1;32m[2]\e[0m Live Host Check"
echo -e "\e[1;32m[3]\e[0m URL Checking"
echo -e "\e[1;32m[4]\e[0m Run All Recon"
echo -e "\e[1;32m[5]\e[0m Re-check / Install Required Tools"
echo -e "\e[1;31m[0]\e[0m Exit"
echo

read -p "➤ Choice: " OPTION
echo

case $OPTION in
  1)
    read -p "[+] Enter target domain: " domain
        if [ -z "$domain" ]
    then 
        echo "No input detected"
        exit 1
        fi

        regex="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"

        if [[ ! "$domain" =~ $regex ]]
    then
        echo "Wrong domain input"
        exit 1
        fi
       echo -e "\e[1;34m[*] Running subdomain enumeration on $domain...\e[0m"
    {
    subfinder -d "$domain" -silent 2>/dev/null
    assetfinder --subs-only "$domain" 2>/dev/null
    curl -s "https://crt.sh/?q=%25.$domain&output=json" \
    | jq -r '.[].name_value' 2>/dev/null \
    | sed 's/\*\.//g'
    } | grep -E '^([a-zA-Z0-9-]+\.)+'"${domain}"'$' \
    | sort -u > "$domain-subs.txt"
    echo -e "\e[1;34m[+] subdomains gotten successfully\e[0m"
    ;;
  2)
    read -p "[+] Enter subdomain: " TARGET
    if [ -z "$TARGET" ]
    then 
        echo "No input detected"
        exit 1
     fi

     regex="^([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}$"
     if [[ ! "$TARGET" =~ $regex ]]
    then
        echo "Wrong domain input"
        exit 1
     fi
    echo -e "\e[1;34m[*] Checking live host...\e[0m"
    httpx -u "$TARGET" \
    -silent \
    -fr \
    -sc \
    -td \
    -location \
    -cl

    ;;
  3)
    read -p "[+] Enter target domain: " domain
     if [ -z "$domain" ]
    then 
        echo "No input detected"
        exit 1
        fi

        regex="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"

        if [[ ! "$domain" =~ $regex ]]
    then
        echo "Wrong domain input"
        exit 1
        fi
    echo -e "\e[1;34m[*] Checking domain for url: $domain\e[0m"
    waybackurls "$domain" > "$domain-url.txt"
    httpx -silent -mc 200,302,403 < "$domain-url.txt" > "$domain-liveurl.txt"
    echo -e "\e[1;34m[+] urls gotten successfully\e[0m"
    ;;
  4)
    read -p "[+] Enter target domain: " domain
     if [ -z "$domain" ]
    then 
        echo "No input detected"
        exit 1
        fi

    regex="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"
        if [[ ! "$domain" =~ $regex ]]
    then
        echo "Wrong domain input"
        exit 1
        fi

    #output directory
    OUTDIR="recon_$domain"
    mkdir -p "$OUTDIR"

    SUB_FILE="$OUTDIR/subs.txt"
    LIVE_FILE="$OUTDIR/live.txt"
    URL_FILE="$OUTDIR/url.txt"
    LIVE_URL="$OUTDIR/liveUrl.txt"
    #subdomains enumeration
    echo -e "\e[1;34m[*] Enumerating subdomains: $domain\e[0m"
    {
        subfinder -d "$domain" -silent 2>/dev/null
        assetfinder --subs-only "$domain" 2>/dev/null
        curl -s "https://crt.sh/?q=%25.$domain&output=json" \
        | jq -r '.[].name_value' 2>/dev/null \
        | sed 's/\*\.//g'
    } | grep -E "\.${domain}$|^${domain}$" \
      | sort -u > "$SUB_FILE"
    echo -e "\e[1;34m[*] Subdomains gotten Successfully \e[0m"

    #live domains enumeration
    echo -e "\e[1;34m[*] Enumerating Live Domains....\e[0m"
    httpx -l "$SUB_FILE" \
    -silent \
    -fr \
    -sc \
    -td \
    -location \
    -cl > "$LIVE_FILE"
    echo -e "\e[1;34m[*] Live domains gotten Successfully\e[0m"

    #urls enumeration
    echo -e "\e[1;34m[*] Enumerating urls from "$SUB_FILE"\e[0m"
    waybackurls < "$SUB_FILE" > "$URL_FILE"
    httpx -silent -mc 200,302,403 < "$URL_FILE" > "$LIVE_URL"
    echo -e "\e[1;34m[*] URLS gotten Successfully\e[0m"
    ;;
  5)
    check_and_install_dependencies
    ;;
  0)
    echo -e "\e[1;31m[!] Exiting CYRECON...\e[0m"
    exit 0
    ;;
  *)
    echo -e "\e[1;31m[!] Invalid option selected\e[0m"
    ;;
esac
