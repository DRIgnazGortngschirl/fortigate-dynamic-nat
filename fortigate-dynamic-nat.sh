#/bin/bash

# If running a systemd service uncomment following lines
# INSTALLPATH=$(egrep -v "^\s*(#|$)" <PATH TO INSTALLATIONS DIRECTORY>config.txt | grep INSTALLPATH | sed 's/INSTALLPATH=//g' | tr -d '\r')
# cd $INSTALLPATH

PARAMETER1=$1 # Get parameter
PARAMETER2=$2 # Get parameter

if [ "$PARAMETER1" = "-h" ]; then                                                                                                                                   # Check for -h parameter
    echo "Usage: ./fortigate-dynamic-nat.sh [OPTION]"                                                                                                               # Display help message
    echo ""                                                                                                                                                         # Display help message
    echo "  -d                   DOMAINMODE (Define a doamin to lookup an compare [Note:] will get pulled from the config.txt file)"                                # Display help message
    echo "  -t                   TESTMODE (Will show the config but will not push it to the FortiGate)"                                                             # Display help message
    echo -e "  -f                   FOCEMODE (Will force to perform a VIP update even if the IP hasn't even changed \e[31mWILL BE PUSHED TO FORTIGATE\e[39m)"       # Display help message
    echo "  -tf                  FOCEMODE & TESTMODE (Will force to perform a VIP update even if the IP hasn't even changed but will not push it to the FortiGate)" # Display help message
    echo "  -h                   HELP Displays this help man page"                                                                                                  # Display the help man page
    exit                                                                                                                                                            # Exit
fi                                                                                                                                                                  # End of Check for -h parameter

STARTED=$(grep InitStart log.txt 2>/dev/null)         # Check for InitStart in log
if [ -z "$STARTED" ]; then                            # Check for InitStart
    echo -e "$(date) InitStart $(date +%s)" >>log.txt # Writing starting point to log
else                                                  # Else if InitStart was found in log.txt
    printf ""                                         # Nothing
fi                                                    # End of InitStart check

FORTIGATEIP=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEIP | sed 's/FORTIGATEIP=//g' | tr -d '\r')                # Get settings from config file
FORTIGATESSHPORT=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATESSHPORT | sed 's/FORTIGATESSHPORT=//g' | tr -d '\r') # Get settings from config file
FORTIGATEUSER=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEUSER | sed 's/FORTIGATEUSER=//g' | tr -d '\r')          # Get settings from config file
FORTIGATEPASSWD=$(egrep -v "^\s*(#|$)" config.txt | grep FORTIGATEPASSWD | sed 's/FORTIGATEPASSWD=//g' | tr -d '\r')    # Get settings from config file

while true; do                                                                                                                     # Main loop
    if [ "$PARAMETER1" = "-d" ] || [ "$PARAMETER2" = "-d" ]; then                                                                  # Check for -d parameter
        DOMAIN=$(egrep -v "^\s*(#|$)" config.txt | grep DOMAIN | sed 's/DOMAIN=//g' | tr -d '\r')                                  # Gets settings from config file
        DNS=$(egrep -v "^\s*(#|$)" config.txt | grep DNS | sed 's/DNS=//g' | tr -d '\r')                                           # Gets settings from config file
        SLEEPBETWEENCHEKS=$(egrep -v "^\s*(#|$)" config.txt | grep SLEEPBETWEENCHEKS | sed 's/SLEEPBETWEENCHEKS=//g' | tr -d '\r') # Gets settings from config file
        IPPRE=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}')                                           # Check the current Public IP of DOMAIN
        if [ "$IPPRE" = ";; connection timed out; no servers could be reached" ]; then
            NOIP=1
            while [ "$NOIP" -eq 1 ]; do
                IPPRE=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}')
                if ! [ "$IPPRE" = ";; connection timed out; no servers could be reached" ]; then
                    NOIP=0
                fi
            done
        else
            echo -e "[i]: Current Public IP for \e[34m$DOMAIN\e[39m is \e[35m$IPPRE\e[39m" # Print output
        fi
        sleep "$SLEEPBETWEENCHEKS"                                                       # Wait till next check if the IP changed
        IPNOW=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}') # Check the current Public IP of DOMAIN to see if it has changed
        if [ "$IPNOW" = ";; connection timed out; no servers could be reached" ]; then
            NOIP=1
            while [ "$NOIP" -eq 1 ]; do
                IPNOW=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}')
                if ! [ "$IPNOW" = ";; connection timed out; no servers could be reached" ]; then
                    NOIP=0
                fi
            done
        else
            MINS=$(echo "$SLEEPBETWEENCHEKS" 60 | awk '{print $1 / $2}')                                                                                            # Calculate wait time in minutes
            echo -e "[i]: Current Public IP for \e[34m$DOMAIN\e[39m after \e[33m$SLEEPBETWEENCHEKS\e[39m seconds (\e[33m$MINS\e[39m minutes) is \e[35m$IPPRE\e[39m" # Print output
        fi
    else                                                                                                                           # Default check hosts Public IP o see if it has changed
        SLEEPBETWEENCHEKS=$(egrep -v "^\s*(#|$)" config.txt | grep SLEEPBETWEENCHEKS | sed 's/SLEEPBETWEENCHEKS=//g' | tr -d '\r') # Gets settings from config file
        IPPRE=$(dig +short myip.opendns.com @resolver1.opendns.com)                                                                # Check the current Public IP of host itself
        if [ "$IPPRE" = ";; connection timed out; no servers could be reached" ]; then
            NOIP=1
            while [ "$NOIP" -eq 1 ]; do
                IPPRE=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}')
                if ! [ "$IPPRE" = ";; connection timed out; no servers could be reached" ]; then
                    NOIP=0
                fi
            done
        else
            echo -e "[i]: Current Public IP for \e[34m$HOSTNAME\e[39m is \e[35m$IPPRE\e[39m" # Print output
        fi
        sleep "$SLEEPBETWEENCHEKS"                                  # Wait till next check if the IP changed
        IPNOW=$(dig +short myip.opendns.com @resolver1.opendns.com) # Check the current Public IP of host itself to see if it has changed
        if [ "$IPNOW" = ";; connection timed out; no servers could be reached" ]; then
            NOIP=1
            while [ "$NOIP" -eq 1 ]; do
                IPNOW=$(nslookup "$DOMAIN" "$DNS" | grep Address | tail -n 1 | awk '{print $2}')
                if ! [ "$IPNOW" = ";; connection timed out; no servers could be reached" ]; then
                    NOIP=0
                fi
            done
        else
            MINS=$(echo "$SLEEPBETWEENCHEKS" 60 | awk '{print $1 / $2}')                                                                                              # Calculate wait time in minutes
            echo -e "[i]: Current Public IP for \e[34m$HOSTNAME\e[39m after \e[33m$SLEEPBETWEENCHEKS\e[39m seconds (\e[33m$MINS\e[39m minutes) is \e[35m$IPPRE\e[39m" # Print output
        fi
    fi                                # End of Check for -d parameter
    if [ "$PARAMETER1" = "-f" ]; then # Check for -f parameter
        IPNOWTEMP="$IPNOW"            # Remember IP for later
        IPNOW=0.0.0.0                 # Set IP to 0.0.0.0 to trigger a config update for the VIPs
    else
        if [ "$PARAMETER1" = "-tf" ]; then # Check for -tf parameter
            IPNOWTEMP="$IPNOW"             # Remember IP for later
            IPNOW=0.0.0.0                  # Set IP to 0.0.0.0 to trigger a config update for the VIPs
        fi
    fi
    if [ "$IPPRE" == "$IPNOW" ]; then                                                            # Compare the resoled IPs
        if [ "$PARAMETER1" = "-d" ]; then                                                        # Check for -d parameter
            echo -e "[i]: Public IP for \e[34m$DOMAIN\e[39m hasn't changed \e[32m$IPNOW\e[39m"   # Print output DOMAIN
        else                                                                                     # Default
            echo -e "[i]: Public IP for \e[34m$HOSTNAME\e[39m hasn't changed \e[32m$IPNOW\e[39m" # Print output SELF
        fi                                                                                       # End of Check for -d parameter
    else                                                                                         # Public IP has changed :( "I hate dynamic IPs"
        if [ "$PARAMETER1" = "-f" ]; then                                                        # Check for -f parameter
            IPNOW="$IPNOWTEMP"                                                                   # Set back the original IP
            echo -e "[i]: \e[7mFOCEMODE\e[27m ### Forced a configuation change even if the IP hasn't changed"
        else
            if [ "$PARAMETER1" = "-tf" ]; then
                IPNOW="$IPNOWTEMP" # Set back the original IP
                echo -e "[i]: \e[7mFOCEMODE\e[27m ### Forced a configuation change even if the IP hasn't changed"
            fi
        fi
        if [ "$PARAMETER1" = "-d" ] || [ "$PARAMETER2" = "-d" ]; then                                                                                                                # Check for -d parameter
            echo -e "[i]: Public IP for \e[34m$DOMAIN\e[39m has changed \e[31m$IPPRE\e[39m --> \e[32m$IPNOW\e[39m"                                                                   # Print output DOMAIN
        else                                                                                                                                                                         # Default
            echo -e "[i]: Public IP for \e[34m$HOSTNAME\e[39m has changed \e[31m$IPPRE\e[39m --> \e[32m$IPNOW\e[39m"                                                                 # Print output SELF
        fi                                                                                                                                                                           # End of Check for -d parameter
        sshpass -p "$FORTIGATEPASSWD" ssh -o LogLevel=QUIET -tt -o "StrictHostKeyChecking=no" "$FORTIGATEUSER"@"$FORTIGATEIP" -p "$FORTIGATESSHPORT" <commands.txt >>config-temp.txt # Pull the current VIP config
        if [[ $(find config-temp.txt -type f -size +1000c 2>/dev/null) ]]; then                                                                                                      # Check for a succsesfull pull
            echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpulled\e[39m"                                                                                                     # Print output
            HOSTNAME=$(head -n 11 config-temp.txt | tail -n 1 | awk '{print $1}')                                                                                                    # Search for the hostanme
            sed -n "/$HOSTNAME/,/end/ p" config-temp.txt | grep -v "$HOSTNAME" | grep -v "uuid" | grep -v "extintf" | sed '/^[[:space:]]*$/d' >config-now.txt                        # Remove HOSTNAME, uuid, extintf and unneeded spaces and emty lines
            rm config-temp.txt                                                                                                                                                       # Remove old temp file
            sed -i "s/$IPPRE/$IPNOW/" config-now.txt                                                                                                                                 # Replace the old IP with the new one
            if [ "$PARAMETER1" = "-t" ]; then                                                                                                                                        # Check for -t parameter
                echo -e "[i]: \e[7mTESTMODE\e[27m ### Will NOT push config"                                                                                                          # Print output
                cat config-now.txt                                                                                                                                                   # Display config
                rm config-now.txt                                                                                                                                                    # Remove old file
                exit                                                                                                                                                                 # Exit
            else
                if [ "$PARAMETER1" = "-tf" ]; then
                    echo -e "[i]: \e[7mTESTMODE\e[27m ### Will NOT push config" # Print output
                    cat config-now.txt                                          # Display config
                    rm config-now.txt                                           # Remove old file
                    exit
                fi
            fi                                                                                                                                                     # End of Check for -t parameter
            echo "exit" >>config-now.txt                                                                                                                           # Exit the SSH session
            sshpass -p "$FORTIGATEPASSWD" ssh -tt -o "StrictHostKeyChecking=no" "$FORTIGATEUSER"@"$FORTIGATEIP" -p "$FORTIGATESSHPORT" <config-now.txt &>/dev/null # Push the updated VIP config
            echo -e "[i]: Config of \e[34m$FORTIGATEIP\e[39m \e[96mpushed\e[39m"                                                                                   # Print output
            rm config-now.txt                                                                                                                                      # Remove old file
            TIMENOW=$(date +%s)                                                                                                                                    # UNIX Time now
            LASTIPCHANGETIME=$(tail -n 1 log.txt | awk 'NF>1{print $NF}' | tr -d '\r')                                                                             # Check UNIX time of last IP chance
            LEASETIMESEC=$((TIMENOW - LASTIPCHANGETIME))                                                                                                           # Calculate lease time in seconds +- $SLEEPBETWEENCHEKS
            LEASETIMEMIN=$(echo "$LEASETIMESEC" 60 | awk '{print $1 / $2}')                                                                                        # Calculate lease time in minutes +- $SLEEPBETWEENCHEKS
            echo "$(date) IP changed after $LEASETIMESEC seconds ($LEASETIMEMIN minutes) ### $IPPRE --> $IPNOW $(date +%s)" >>log.txt                              # Writing event to log
            echo -e "[i]: IP changed after \e[33m$LEASETIMESEC\e[39m seconds (\e[33m$LEASETIMEMIN\e[39m minutes) ### \e[31m$IPPRE\e[39m --> \e[32m$IPNOW\e[39m"    # Print output
        else                                                                                                                                                       #  Pull unsuccsesfull
            echo -e "[err]: Pulling config of \e[34m$FORTIGATEIP\e[39m Failed"
        fi

    fi # End of if check loop
done   # End of Main loop
