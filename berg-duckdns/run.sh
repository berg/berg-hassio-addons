#!/bin/bash
set -e

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir
CONFIG_PATH=/data/options.json

# Let's encrypt
LE_TERMS=$(jq --raw-output '.lets_encrypt.accept_terms' $CONFIG_PATH)
LE_DOMAINS=$(jq --raw-output '((.domains // []) + (.internal_domains // [])) | .[]' $CONFIG_PATH)
LE_UPDATE="0"

# DuckDNS
TOKEN=$(jq --raw-output '.token' $CONFIG_PATH)
DOMAINS=$(jq --raw-output '.domains // [] | join(",")' $CONFIG_PATH)
INTERNAL_DOMAINS=$(jq --raw-output '.internal_domains // [] | join(",")' $CONFIG_PATH)
WAIT_TIME=$(jq --raw-output '.seconds' $CONFIG_PATH)

# Function that performe a renew
function le_renew() {
    local domain_args=()
  
    # Prepare domain for Let's Encrypt
    for domain in $LE_DOMAINS; do
        domain_args+=("--domain" "$domain")
    done
    
    dehydrated --cron --hook ./hooks.sh --challenge dns-01 "${domain_args[@]}" --out "$CERT_DIR" --config "$WORK_DIR/config" || true
    LE_UPDATE="$(date +%s)"
}

# Register/generate certificate if terms accepted
if [ "$LE_TERMS" == "true" ]; then
    # Init folder structs
    mkdir -p "$CERT_DIR"
    mkdir -p "$WORK_DIR"
    
    # Generate new certs
    if [ ! -d "$CERT_DIR/live" ]; then
        # Create empty dehydrated config file so that this dir will be used for storage
        touch "$WORK_DIR/config"
        
        dehydrated --register --accept-terms --config "$WORK_DIR/config"
    fi
fi

# Run duckdns
while true; do
    if [ ! -z "$DOMAINS" ]; then
        answer="$(curl -sk "https://www.duckdns.org/update?domains=$DOMAINS&token=$TOKEN&ip=&verbose=true")" || true
        echo "[external] $(date): $answer"
    fi

    if [ ! -z "$INTERNAL_DOMAINS" ]; then
        internal_ip=$(ip -f inet addr show eth0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')

        answer="$(curl -sk "https://www.duckdns.org/update?domains=$INTERNAL_DOMAINS&token=$TOKEN&ip=$internal_ip&verbose=true")" || true
        echo "[internal] $(date): $answer"
    fi

    now="$(date +%s)"
    if [ "$LE_TERMS" == "true" ] && [ $((now - LE_UPDATE)) -ge 43200 ]; then
        le_renew
    fi
    
    sleep "$WAIT_TIME"
done
