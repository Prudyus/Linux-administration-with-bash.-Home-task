#!/usr/bin/env bash
#
#% NAME
#%    ${SCRIPT_NAME} - Check network host/port availability
#%
#% SYNOPSIS
#%    ${SCRIPT_NAME} --option <target>
#%
#% DESCRIPTION
#%    Scan a given network for available hosts or scan given host for
#%    available ports.
#%
#%    --all
#%           Output every available host ip in a <target> subnet.
#%
#%    --target
#%           Output every opened port on a <target> host IP.
#%
#%    --help
#%           Output this documentation.
#%
#% EXAMPLES
#%    ${SCRIPT_NAME} --all 192.168.0.0/24
#%        Find all online hosts in the 192.168.0.0/24 subnet.
#%
#%    ${SCRIPT_NAME} --all 192.168.12.107/24
#%        Find all online hosts in the 192.168.12.0/24 subnet.
#%
#%    ${SCRIPT_NAME} --target 192.168.0.43
#%        Find all available port on a target host.
#%
################################################################################
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#    set -e  # Exit immediately if a command exits with a non-zero status.
#            # Better use trap instead of this.
#    set -Eeuo pipefail
#
################################################################################
# Original ip_list idea:
# https://stackoverflow.com/questions/16986879/bash-script-to-list-all-ips-in-prefix
#

##  UTILITY FUNCTIONS ##########################################################

usage() {
    headFilter="^#%"
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
        '#!'*) # Shebang line
            ;;
        '' | '##'* | [!#]*) # End of Help block
            exit "${1:-0}"
            ;;
        *) # Help line
            printf '%s\n' "${line:2}" | sed -e "s/${headFilter}//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"
            ;;
        esac
    done <"$0"
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}


##  USER FUNCTIONS #############################################################

ip_list() { #   Usage: ip_list 192.168.0.0/24
    BASE_IP=${1%/*}
    IP_CIDR=${1#*/}

    if [ ${IP_CIDR} -lt 8 ]; then
        echo "Max range is /8."
        exit
    fi

    IP_MASK=$((0xFFFFFFFF << (32 - ${IP_CIDR})))

    IFS=. read a b c d <<<${BASE_IP}

    ip=$((($b << 16) + ($c << 8) + $d))

    ipstart=$(((${ip} & ${IP_MASK}) + 1))
    ipend=$(((${ipstart} | ~${IP_MASK}) & 0x7FFFFFFF - 1))

    seq ${ipstart} ${ipend} | while read i; do
        echo $a.$((($i & 0xFF0000) >> 16)).$((($i & 0xFF00) >> 8)).$(($i & 0x00FF))
    done
}

do_ping() {     # Usage: do_ping 192.168.0.1
    local IP="$1"
    if ping -c1 -w1 "$IP" &>/dev/null; then
        local domainname
        domainname=$(nslookup "$IP" | awk -F 'name = |.$' 'NR==1{print $2}')
        echo -ne "$IP\t$domainname\n"
    fi
}

scan_ip() {     # Usage: scan_ip 192.168.0.0/24
    export -f do_ping
    ip_list "$1" | xargs -I {} -P10 bash -c 'do_ping "$@"' _ {}
    exit 0
}


# scan_port() {       # Usage: scan_port 192.168.1.1
#     for port in {0..65535}; do
#         #(echo >/dev/tcp/${1}/${port}) &>/dev/null && echo "$port opened" #|| echo "$port closed"
#         timeout 1 bash -c "echo >/dev/tcp/${1}/${port}" &>/dev/null && echo "$port opened" 
#     done
#     exit 0
# }


scan_port() {       # Usage: scan_port 192.168.1.1 80
    local IP="$1"
    local PORT="$2"

    bash -c "echo >/dev/tcp/${IP}/${PORT}" &>/dev/null && echo "$PORT opened"
}

scan_ports() {       # Usage: scan_ports 192.168.1.1
    local IP="$1"
    export -f scan_port
    # if you want to check well-known ports only
    # cat /etc/services | grep "/tcp" | awk '{ print $2 }' | sed "s_/tcp__" | \
    #     xargs -I % bash -c "scan_port $IP %"
    seq 0 65535 | xargs -I % bash -c "scan_port $IP %"
    exit 0
}



##  MAIN FUNCTION  #############################################################

main() {
    while :; do
        case "${1-}" in
        --all)
            target="${2-}"
            [[ -z "$target" ]] || scan_ip "$target";
            usage 13
        ;;
        --target)
            target="${2-}"
            [[ -z "$target" ]] || scan_ports "$target";
            usage 13
        ;;
        --help) usage 13 ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    return 0
}

##  PARAMETERS CHECK  ##########################################################

if [[ $# -lt 1 ]]; then
    usage 13
fi

##  MAIN LOGIC  ################################################################

main "$@"
