#/bin/bash

# If running a systemd service
# INSTALLPATH=$(egrep -v "^\s*(#|$)" <PATH TO INSTALLATIONS DIRECTORY>config.txt | grep INSTALLPATH | sed 's/INSTALLPATH=//g' | tr -d '\r')
# cd $INSTALLPATH

PARAMETER=$1     # Get parameter

if [ "$PARAMETER" = "-h" ]; then # Check for -h parameter
    echo "Usage: ./fortigate-dynamic-nat.sh [OPTION]"                                                                                # Display help message
    echo ""                                                                                                                          # Display help message
    echo "  -d                   DOMAINMODE (Define a doamin to lookup an compare [Note:] will get pulled from the config.txt file)" # Display help message
    echo "  -t                   TESTMODE (Will show the config but will not push it to the FortiGate)"                              # Display help message
    echo "  -f                   FOCEMODE (Will force to perform a VIP update even if the IP hasn't even changed)"
    echo "  -tf                  FOCEMODE & TESTMODE (Will force to perform a VIP update even if the IP hasn't even changed but will not push it to the FortiGate)"
    echo "  -h                   Display this help page" # Display the help message
    exit                                                 # Exit
fi                                                 # End of Check for -h parameter

started=$(grep InitStart log.txt 2>/dev/null)                                                                           # Check for InitStart in log
if [ -z "$started" ]; then # Check for InitStart
    echo -e "$(date) InitStart $(date +%s)" >>log.txt # Writing starting point to log
else # Else if InitStart was found in log.txt
    printf "" # Nothing
fi # End of InitStart check

FORTIGATEIP=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEIP | sed 's/FORTIGATEIP=//g' | tr -d '\r')                # Get settings from config gile
FORTIGATESSHPORT=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATESSHPORT | sed 's/FORTIGATESSHPORT=//g' | tr -d '\r') # Get settings from config gile
FORTIGATEUSER=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEUSER | sed 's/FORTIGATEUSER=//g' | tr -d '\r')          # Get settings from config gile
FORTIGATEPASSWD=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEPASSWD | sed 's/FORTIGATEPASSWD=//g' | tr -d '\r')    # Get settings from config gile

while true; do # Main loop
    if [ "$PARAMETER" = "-d" ]; then # Check for -d parameter
        DOMAIN=$(egrep -v "^\s*(#|$)" config.txt | grep DOMAIN | sed 's/DOMAIN=//g' | tr -d '\r')                                                               # Gets settings from config gile
        DNSRESOLVER=$(egrep -v "^\s*(#|$)" config.txt | grep DNSRESOLVER | sed 's/DNSRESOLVER=//g' | tr -d '\r')                                                # Gets settings from config gile
        SLEEPBETWEENCHEKS=$(egrep -v "^\s*(#|$)" config.txt | grep SLEEPBETWEENCHEKS | sed 's/SLEEPBETWEENCHEKS=//g' | tr -d '\r')                              # Gets settings from config gile
        ippre=$(nslookup "$DOMAIN" "$DNSRESOLVER" | grep Address | tail -n 1 | awk '{print $2}')                                                                # Check the current Public IP of DOMAIN
        echo -e "[i]: Current Public IP for \e[34m$DOMAIN\e[39m is \e[35m$ippre\e[39m"                                                                          # Print output
        sleep "$SLEEPBETWEENCHEKS"                                                                                                                              # Wait till next check if the IP changed
        ipnow=$(nslookup "$DOMAIN" "$DNSRESOLVER" | grep Address | tail -n 1 | awk '{print $2}')                                                                # Check the current Public IP of DOMAIN to see if it has changed
        mins=$(echo "$SLEEPBETWEENCHEKS" 60 | awk '{print $1 / $2}')                                                                                            # Calculate wait time in minutes
        echo -e "[i]: Current Public IP for \e[34m$DOMAIN\e[39m after \e[33m$SLEEPBETWEENCHEKS\e[39m seconds (\e[33m$mins\e[39m minutes) is \e[35m$ippre\e[39m" # Print output
    else # Default check hosts Public IP o see if it has changed
        SLEEPBETWEENCHEKS=$(egrep -v "^\s*(#|$)" config.txt | grep SLEEPBETWEENCHEKS | sed 's/SLEEPBETWEENCHEKS=//g' | tr -d '\r')                                  # Gets settings from config gile
        ippre=$(dig +short myip.opendns.com @resolver1.opendns.com)                                                                                                 # Check the current Public IP of host itself
        echo -e "[i]: Current Public IP for \e[34m$(hostname)\e[39m is \e[35m$ippre\e[39m"                                                                          # Print output
        sleep "$SLEEPBETWEENCHEKS"                                                                                                                                  # Wait till next check if the IP changed
        ipnow=$(dig +short myip.opendns.com @resolver1.opendns.com)                                                                                                 # Check the current Public IP of host itself to see if it has changed
        mins=$(echo "$SLEEPBETWEENCHEKS" 60 | awk '{print $1 / $2}')                                                                                                # Calculate wait time in minutes
        echo -e "[i]: Current Public IP for \e[34m$(hostname)\e[39m after \e[33m$SLEEPBETWEENCHEKS\e[39m seconds (\e[33m$mins\e[39m minutes) is \e[35m$ippre\e[39m" # Print output
    fi # End of Check for -d parameter
    if [ "$PARAMETER" = "-f" ]; then # Check for -f parameter
        ipnowtemp="$ipnow" # Remember IP for later
        ipnow=0.0.0.0      # Set IP to 0.0.0.0 to trigger a config update for the VIPs
    else
        if [ "$PARAMETER" = "-tf" ]; then
            ipnowtemp="$ipnow" # Remember IP for later
            ipnow=0.0.0.0      # Set IP to 0.0.0.0 to trigger a config update for the VIPs
        fi
    fi
    if [ "$ippre" == "$ipnow" ]; then # Compare the resoled IPs
        if [ "$PARAMETER" = "-d" ]; then # Check for -d parameter
            echo -e "[i]: Public IP for \e[34m$DOMAIN\e[39m hasn't changed \e[32m$ipnow\e[39m" # Print output DOMAIN
        else # Default
            echo -e "[i]: Public IP for \e[34m$(hostname)\e[39m hasn't changed \e[32m$ipnow\e[39m" # Print output SELF
        fi # End of Check for -d parameter
    else # Public IP has changed :( "I hate dynamic IPs"
        if [ "$PARAMETER" = "-f" ]; then # Check for -f parameter
            ipnow="$ipnowtemp" # Set back the original IP
            echo -e "[i]: \e[7mFOCEMODE\e[27m ### Forced a configuation change even if the IP hasn't changed"
        else
            if [ "$PARAMETER" = "-tf" ]; then
                ipnow="$ipnowtemp" # Set back the original IP
                echo -e "[i]: \e[7mFOCEMODE\e[27m ### Forced a configuation change even if the IP hasn't changed"
            fi
        fi
        if [ "$PARAMETER" = "-d" ]; then # Check for -d parameter
            echo -e "[i]: Public IP for \e[34m$DOMAIN\e[39m has changed \e[31m$ippre\e[39m --> \e[32m$ipnow\e[39m" # Print output DOMAIN
        else # Default
            echo -e "[i]: Public IP for \e[34m$(hostname)\e[39m has changed \e[31m$ippre\e[39m --> \e[32m$ipnow\e[39m" # Print output SELF
        fi # End of Check for -d parameter
        sshpass -p "$FORTIGATEPASSWD" ssh -o LogLevel=QUIET -tt -o "StrictHostKeyChecking=no" "$FORTIGATEUSER"@"$FORTIGATEIP" -p "$FORTIGATESSHPORT" <commands.txt >>config-temp.txt # Pull the current VIP config
        echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpulled\e[39m"                                                                                                         # Print output
        hostname=$(head -n 11 config-temp.txt | tail -n 1 | awk '{print $1}')                                                                                                        # Search for the hostanme
        sed -n "/$hostname/,/end/ p" config-temp.txt | grep -v "$hostname" | grep -v "uuid" | grep -v "extintf" | sed '/^[[:space:]]*$/d' >config-now.txt                            # Remove hostname, uuid, extintf and unneeded spaces and emty lines
        rm config-temp.txt                                                                                                                                                           # Remove old temp file
        sed -i "s/$ippre/$ipnow/" config-now.txt                                                                                                                                     # Replace the old IP with the new one
        if [ "$PARAMETER" = "-t" ]; then # Check for -t parameter
            echo -e "[i]: \e[7mTESTMODE\e[27m ### Will NOT push config" # Print output
            cat config-now.txt                                          # Display config
            rm config-now.txt                                           # Remove old file
            exit                                                        # Exit
        else
            if [ "$PARAMETER" = "-tf" ]; then
                echo -e "[i]: \e[7mTESTMODE\e[27m ### Will NOT push config" # Print output
                cat config-now.txt                                          # Display config
                rm config-now.txt                                           # Remove old file
                exit
            fi
        fi # End of Check for -t parameter
        echo "exit" >>config-now.txt                                                                                                                                                 # Exit the SSH session
        sshpass -p "$FORTIGATEPASSWD" ssh -tt -o "StrictHostKeyChecking=no" "$FORTIGATEUSER"@"$FORTIGATEIP" -p "$FORTIGATESSHPORT" <config-now.txt &>/dev/null                       # Push the updated VIP config
        echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpushed\e[39m"                                                                                                         # Print output
        rm config-now.txt                                                                                                                                                            # Remove old file
        timenow=$(date +%s)                                                                                                                                                          # UNIX Time now
        lastipchangetime=$(tail -n 1 log.txt | awk 'NF>1{print $NF}' | tr -d '\r')                                                                                                   # Check UNIX time of last IP chance
        leasetimesec=$((timenow - lastipchangetime))                                                                                                                                 # Calculate lease time in seconds +- $SLEEPBETWEENCHEKS
        leasetimemin=$(echo "$leasetimesec" 60 | awk '{print $1 / $2}')                                                                                                              # Calculate lease time in minutes +- $SLEEPBETWEENCHEKS
        echo "$(date) IP changed after $leasetimesec seconds ($leasetimemin minutes) ### $ippre --> $ipnow $(date +%s)" >>log.txt                                                    # Writing event to log
        echo -e "[i]: IP changed after \e[33m$leasetimesec\e[39m seconds (\e[33m$leasetimemin\e[39m minutes) ### \e[31m$ippre\e[39m --> \e[32m$ipnow\e[39m"                          # Print output
    fi                          # End of if check loop
done                          # End of Main loop
