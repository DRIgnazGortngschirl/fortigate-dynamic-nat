#/bin/bash

PARAMETER=$1                                                                                                                                                                    # Get parameter

if [ "$PARAMETER" = "-h" ]; then                                                                                                                                                # Check for -h parameter
    echo "Usage: ./fortigate-dynamic-nat.sh [OPTION]"                                                                                                                           # Display help message
    echo ""                                                                                                                                                                     # Display help message
    echo "  -t                   Enter TESTMODE (Will show you the config and will not push it)"                                                                                # Display help message
    echo "  -h                   Display this help page"                                                                                                                        # Display help message
    exit                                                                                                                                                                        # Exit
fi                                                                                                                                                                              # End of Check for -h parameter

started=$(grep InitStart log.txt 2>/dev/null)                                                                                                                                   # Check for InitStart in log
if [ -z "$started" ]; then                                                                                                                                                      # Check for InitStart
    echo -e "$(date) InitStart $(date +%s)" >>log.txt                                                                                                                           # Writing starting point to log
else                                                                                                                                                                            # Else if InitStart was found in log.txt
    printf ""                                                                                                                                                                   # Nothing
fi                                                                                                                                                                              # End of InitStart check

FORTIGATEIP=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEIP | sed 's/FORTIGATEIP=//g' | tr -d '\r')                                                                        # Get settings from config gile
FORTIGATESSHPORT=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATESSHPORT | sed 's/FORTIGATESSHPORT=//g' | tr -d '\r')                                                         # Get settings from config gile
FORTIGATEUSER=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEUSER | sed 's/FORTIGATEUSER=//g' | tr -d '\r')                                                                  # Get settings from config gile
FORTIGATEPASSWD=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEPASSWD | sed 's/FORTIGATEPASSWD=//g' | tr -d '\r')                                                            # Get settings from config gile

while true; do                                                                                                                                                                  # Main loop
    DOMAIN=$(egrep -v "^\s*(#|$)" config.txt | grep DOMAIN | sed 's/DOMAIN=//g' | tr -d '\r')                                                                                   # Gets settings from config gile
    DNS=$(egrep -v "^\s*(#|$)" config.txt | grep DNS | sed 's/DNS=//g' | tr -d '\r')                                                                                            # Gets settings from config gile
    SLEEPBETWEENCHEKS=$(egrep -v "^\s*(#|$)" config.txt | grep SLEEPBETWEENCHEKS | sed 's/SLEEPBETWEENCHEKS=//g' | tr -d '\r')                                                  # Gets settings from config gile
    ippre=$(nslookup $DOMAIN $DNS | grep Address | tail -n 1 | awk '{print $2}')                                                                                                # Check the current IP of DOMAIN
    echo -e "[i]: Current IP for \e[34m$DOMAIN\e[39m is \e[35m$ippre\e[39m"                                                                                                     # Print output
    sleep $SLEEPBETWEENCHEKS                                                                                                                                                    # Wait till next check if the IP changed
    ipnow=$(nslookup $DOMAIN $DNS | grep Address | tail -n 1 | awk '{print $2}')                                                                                                # Check the current IP of DOMAIN to see if it has changed
    mins=$(echo $SLEEPBETWEENCHEKS 60 | awk '{print $1 / $2}')                                                                                                                  # Calculate wait time in minutes
    echo -e "[i]: Current IP for \e[34m$DOMAIN\e[39m after \e[33m$SLEEPBETWEENCHEKS\e[39m secounds (\e[33m$mins\e[39m minutes) is \e[35m$ippre\e[39m"                           # Print output
    if [ "$ippre" == "$ipnow" ]; then                                                                                                                                           # Compare the resoled IPs
        echo -e "[i]: IP for \e[34m$DOMAIN\e[39m hasn't chnaged \e[32m$ipnow\e[39m"                                                                                             # Print output
    else                                                                                                                                                                        # IP has changed :( "I hate dynamic IPs"
        echo -e "[i]: IP changed \e[31m$ippre\e[39m --> \e[32m$ipnow\e[39m"                                                                                                     # Print output
        sshpass -p "$FORTIGATEPASSWD" ssh -o LogLevel=QUIET -tt -o "StrictHostKeyChecking=no" $FORTIGATEUSER@$FORTIGATEIP -p $FORTIGATESSHPORT <commands.txt >>config-temp.txt  # Pull the current VIP config
        echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpulled\e[39m"                                                                                                    # Print output
        hostname=$(head -n 11 config-temp.txt | tail -n 1 | awk '{print $1}')                                                                                                   # Search for the hostanme
        sed -n "/$hostname/,/end/ p" config-temp.txt | grep -v "$hostname" | grep -v "uuid" | grep -v "extintf" | sed '/^[[:space:]]*$/d' >config-now.txt                       # Remove hostname, uuid, extintf and unneeded spaces and emty lines
        rm config-temp.txt                                                                                                                                                      # Remove old temp file
        sed -i "s/$ippre/$ipnow/" config-now.txt                                                                                                                                # Replace the old IP with the new one
        if [ "$PARAMETER" = "-t" ]; then                                                                                                                                        # Check for -t parameter
            echo "[i]: TESTMODE will not push config"                                                                                                                           # Print output
            cat config-now.txt                                                                                                                                                  # Display config
            exit                                                                                                                                                                # Exit
        fi                                                                                                                                                                      # End of Check for -t parameter
        echo "exit" >>config-now.txt                                                                                                                                            # Exit the SSH session
        sshpass -p "$FORTIGATEPASSWD" ssh -tt -o "StrictHostKeyChecking=no" $FORTIGATEUSER@$FORTIGATEIP -p $FORTIGATESSHPORT <config-now.txt &>/dev/null                        # Push the updated VIP config
        echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpushed\e[39m"                                                                                                    # Print output
        rm config-now.txt                                                                                                                                                       # Remove old file
        timenow=$(date +%s)                                                                                                                                                     # UNIX Time now
        lastipchangetime=$(tail -n 1 log.txt | awk 'NF>1{print $NF}' | tr -d '\r')                                                                                              # Check UNIX time of last IP chance
        leasetimesec=$((timenow - lastipchangetime))                                                                                                                            # Calculate lease time in secounds +- $SLEEPBETWEENCHEKS
        leasetimemin=$(echo $leasetimesec 60 | awk '{print $1 / $2}')                                                                                                           # Calculate lease time in minutes +- $SLEEPBETWEENCHEKS
        echo "$(date) IP chnaged after $leasetimesec secounds ($leasetimemin minutes) ### $ippre --> $ipnow $(date +%s)" >>log.txt                                              # Writing event to log
        echo -e "[i]: IP chnaged after \e[33m$leasetimesec\e[39m secounds (\e[33m$leasetimemin\e[39m minutes) ### \e[31m$ippre\e[39m --> \e[32m$ipnow\e[39m"                    # Print output
    fi                                                                                                                                                                          # End of if check loop
done                                                                                                                                                                            # End of Main loop
