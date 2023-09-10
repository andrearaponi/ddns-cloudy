#!/bin/bash

# A simple script to update your DNS records on CloudFlare. This script leverages CloudFlare's API to dynamically update DNS records. 
# https://github.com/andrearaponi/ddns-cloudy

CONFIG_FILE="$HOME/.cloudflare_update_config"
LOG_FILE="/var/log/cloudflare_update.log"
SCRIPT_NAME=$(basename "$0")

# Check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Please use 'sudo' or run as the root user."
        exit 1
    fi
}

# Check if another instance of the script is already running
check_running_instance() {
    RUNNING_PIDS=$(ps aux | grep "$SCRIPT_NAME" | grep -vE "grep|$$|sudo" | awk '{ if ($8 != "Ss" && $8 != "S+") print $2 }')
    if [ ! -z "$RUNNING_PIDS" ]; then
        echo "Another instance of the script is already running with PIDs: $RUNNING_PIDS."
        read -p "Do you want to stop them? [yes/no]: " stop_response
        stop_response=$(echo "$stop_response" | tr '[:upper:]' '[:lower:]')

        if [[ "$stop_response" == "yes" || "$stop_response" == "y" ]]; then
            for pid in $RUNNING_PIDS; do
                kill -9 $pid
            done
            echo "Stopped all running instances."
        else
            exit 1
        fi
    fi
}

# Check if config file exist
check_config_exists() {
    if [ -f "$CONFIG_FILE" ]; then
        return 0 
    else
        return 1 
    fi
}


# Check if crontab exist
check_crontab_exists() {
    if crontab -l | grep -q "$SCRIPT_NAME"; then
        return 0
    else
        return 1
    fi
}



# Check if script is already installed
check_installation_status() {
    if [ -f "$CONFIG_FILE" ] || [ -f "/usr/local/bin/$SCRIPT_NAME" ]; then
        echo "⚠️  The script seems to be already installed. Do you want to:"
        echo "1) Run it"
        echo "2) Uninstall it"
        read -p "Choose an option (1/2): " choice
        
        case $choice in
            1) 
                echo "Running the script..."
                # Load existing configuration and run IP check
                source $CONFIG_FILE

                update_dns_record
                if ! check_crontab_exists; then
                    add_to_crontab
                fi
                exit 0
                
                ;;
            2)
                echo "Uninstalling the script..."
                
                # Remove configuration file
                [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"
                
                # Remove script from /usr/local/bin
                [ -f "/usr/local/bin/$SCRIPT_NAME" ] && rm "/usr/local/bin/$SCRIPT_NAME"
                
                # Remove from crontab
                crontab -l | grep -v "$SCRIPT_NAME" | crontab -
                
                echo "Uninstallation completed."
                exit 0
                ;;
            *)
                echo "Invalid option. Exiting."
                exit 1
                ;;
        esac
    else
        # If the script is not installed, start the initialization procedure
        initialize_configuration
        add_to_crontab
        exit 0
    fi
}

# Update dns records
update_dns_record() {
    MYIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
    CHECK_IP=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${MY_ZONE_ID}/dns_records/${MY_DNS_RECORD}" -H "X-Auth-Email: ${MY_EMAIL}" -H "X-Auth-Key: ${MY_API_KEY}" -H "Content-Type: application/json" 2>/dev/null | sed -n 's/.*"content":"\(.*\)","proxi.*/\1/p')

    if [ "$MYIP" != "$CHECK_IP" ]; then
        echo "INFO $(date), MESSAGE:$CHECK_IP updated to -->  $MYIP" >> $LOG_FILE
        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${MY_ZONE_ID}/dns_records/${MY_DNS_RECORD}" -H "Content-Type: application/json" -H "X-Auth-Email: ${MY_EMAIL}" -H "X-Auth-Key: ${MY_API_KEY}" -H "cache-control: no-cache" -d "{\"type\" : \"A\", \"name\" : \"${MY_DNS_RECORD_NAME}\", \"content\" : \"${MYIP}\", \"proxied\": ${PROXY_VALUE}, \"ttl\": ${TTL_VALUE} }" > /dev/null
    fi
}

# Check if the configuration file exists
initialize_configuration() {
    echo ""
    echo ""
    echo "================================================"
    echo "  🚀 Initial Configuration for $SCRIPT_NAME 🚀  "
    echo "================================================"

    read -p "Enter your MY_ZONE_ID: " MY_ZONE_ID
    read -p "Enter your MY_DNS_RECORD: " MY_DNS_RECORD
    read -p "Enter your MY_DNS_RECORD_NAME: " MY_DNS_RECORD_NAME
    read -p "Enter your MY_EMAIL: " MY_EMAIL
    read -p "Enter your MY_API_KEY: " MY_API_KEY
    read -p "Enter the interval in minutes for crontab: " CRON_INTERVAL
    read -p "Enable proxy (true/false, default is false): " PROXY_VALUE
    if [[ "$PROXY_VALUE" != "true" ]]; then
        PROXY_VALUE=false
    fi
    read -p "Enter TTL value (default is 120): " TTL_VALUE
        TTL_VALUE=${TTL_VALUE:-120}
    echo ""

    echo "-------------------------------------------"
    echo "            Confirm your inputs            "
    echo "-------------------------------------------"
    echo "MY_ZONE_ID: $MY_ZONE_ID"
    echo "MY_DNS_RECORD: $MY_DNS_RECORD"
    echo "MY_DNS_RECORD_NAME: $MY_DNS_RECORD_NAME"
    echo "MY_EMAIL: $MY_EMAIL"
    echo "MY_API_KEY: $MY_API_KEY"
    echo "CRON INTERVAL: $CRON_INTERVAL minutes"
    echo "PROXY_VALUE: $PROXY_VALUE"
    echo "TTL_VALUE: $TTL_VALUE minutes"
    echo "-------------------------------------------"
    
    while true; do
        read -p "Are these values correct? [yes/no]: " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')
        if [[ "$confirmation" == "yes" || "$confirmation" == "y" ]]; then
            echo -e "MY_ZONE_ID=$MY_ZONE_ID\nMY_DNS_RECORD=$MY_DNS_RECORD\nMY_DNS_RECORD_NAME=$MY_DNS_RECORD_NAME\nMY_EMAIL=$MY_EMAIL\nMY_API_KEY=$MY_API_KEY\nCRON_INTERVAL=$CRON_INTERVAL\nPROXY_VALUE=$PROXY_VALUE\nTTL_VALUE=$TTL_VALUE" > $CONFIG_FILE
            echo ""
            echo "✨DONE!✨"
            break
        elif [[ "$confirmation" == "no" || "$confirmation" == "n" ]]; then
            exit 1
        fi
    done
    
    
    # Copy the script to /usr/local/bin and set execution permissions
    sudo cp "$0" "/usr/local/bin/$SCRIPT_NAME"
    sudo chmod +x "/usr/local/bin/$SCRIPT_NAME"
    
    # Load configuration
    source $CONFIG_FILE
}

add_to_crontab() {
    (crontab -l 2>/dev/null; echo "*/$CRON_INTERVAL * * * * /usr/local/bin/${SCRIPT_NAME} run") | crontab -
}

main(){
    if [[ "$1" == "run" ]]; then
        # If the script runs with the "run" argument, execute the update_dns_record function
        if check_config_exists; then
            source $CONFIG_FILE
            update_dns_record
        else
            echo "ERROR $(date),MESSAGE:Configuration file dose not exist" >> $LOG_FILE
        fi

    else
        check_root
        check_running_instance
        check_installation_status
    fi
}

main "$@"





