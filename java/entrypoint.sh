#!/bin/bash

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

# Agent.jar download and verification
AGENT_JAR="/home/container/agent.jar"
AGENT_URL="https://service.koara.io/kg-agent/agent.jar"
AGENT_MD5_URL="https://service.koara.io/kg-agent/agent.jar.md5"

download_agent() {
    if curl -fsSL -o "$AGENT_JAR" "$AGENT_URL"; then
        return 0
    else
        return 1
    fi
}

verify_agent() {
    if [ ! -f "$AGENT_JAR" ]; then
        return 1
    fi
        
    REMOTE_MD5=$(curl -fsSL "$AGENT_MD5_URL" | awk '{print $1}')
    
    LOCAL_MD5=$(md5sum "$AGENT_JAR" | awk '{print $1}')
    
    if [ "$LOCAL_MD5" = "$REMOTE_MD5" ]; then
        return 0
    else
        printf "\033[1m\033[33mAgent.jar MD5 mismatch (local: %s, remote: %s)\033[0m\n" "$LOCAL_MD5" "$REMOTE_MD5"
        return 1
    fi
}

# Check if agent.jar exists and verify it
if ! verify_agent; then
    download_agent || exit 1
fi

printf "\033[1m\033[33mcontainer@koaragames~ \033[0mjava -version\n"
java -version

PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

printf "\033[1m\033[33mcontainer@koaragames~ \033[0m%s\n" "$PARSED"
exec env ${PARSED}