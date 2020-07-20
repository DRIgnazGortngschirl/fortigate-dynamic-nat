[![Codacy Badge](https://api.codacy.com/project/badge/Grade/d287c9c868e649e6a753224aeea9c3c1)](https://www.codacy.com/manual/MrMarioMichel/fortigate-dynamic-nat?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=MrMarioMichel/fortigate-dynamic-nat&amp;utm_campaign=Badge_Grade)

# Fortigate Dynamic Nat
This scrip can automatically update a VIP address from public/external to local/internal.

## Why I created this
I'm currently having a dynamic public IP address from my ISP. Due to the fact that you need to set a public/external IP address (not just the interface) this public IP address been set will be outdated as soon the DHCP server decides to give, after your lease expires, a different IP address then before. Actually totally useless because you can also use as source address 0.0.0.0 .

## What is the scrip doing
Basically it's a watcher and waits a defined time till the IP address gets checked and compared against the previous checked public IP address if it has changed. If it has changed, it will pull the config from the FortiGate change **only the public IP address of the VIPs that has got now the old address** and will change it to the new one.

### Output of the script
![alt text](https://pics.mariomichel.com/lmszkp.png)

### Output if you use -tf -d  (see notes for infos) 
![alt text](https://pics.mariomichel.com/9drukz.png)

*Note : The script has been run in the force and test mode ( -ft ) Therefor is a line with the note that the script was executed with an additional parameter. "FORCEMODE" and "TESTMODE"

### Output the IP changes (see notes for infos) 
![alt text](https://pics.mariomichel.com/vridnd.png)

*Note : The script has been run in the force mode ( -f ) Therefor is a line with the note that the script was executed with an additional parameter. "FORCEMODE"

## Logging
The scrip will keep a log of all events (not changed public IP addresses after the defined time will not be logged/ignored).
