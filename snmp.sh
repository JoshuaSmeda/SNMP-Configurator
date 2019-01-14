#!/bin/bash

## Title:         snmp.sh
## Version:	  1.0
## Description:   Installs SNMP service and adds SNMP community on Ubuntu/CentOS systems
## Author(s):     Joshua Smeda
## Output:        Write to File
## Input:         N/A
## Usage:         ./snmp_1grid.sh
## Options:	  stdout
##
## Notes & Todo:
##
## 1. Displays banner asking user how they want to proceed
## 2. Checks system and chooses command path based on if system is running CentOS or Ubuntu
## 3. Checks to see if the snmp service is active and if 1-grid snmp communties are already written to configuration. If active, perform the firewall checks on iptables/firewalld and ufw
## 4. If the service fails step 3, then restart the service and perform the firewall checks on iptables/firewalld and ufw
## 5. Performs snmp community check and adds 1-grid communties should the script not find the communties present.
## 6. If the service is still reporting as not running. Script installs and configures the snmp service should it not find it running on the appriorate system.
## 7. Requires the script to be run with sudo on Ubuntu
##-----------------------------------------------------------------------------


# Variable Declaration
LBLUE='\033[1;36m'
GREY='\033[0;37m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NOCOL='\033[0m'
service="snmpd"
community1="rocommunity ghspublic default"
community2="rocommunity6 ghspublic default"
iptables="$(service iptables status | grep "41.185.120.20" | grep -m 1 -o ACCEPT)" 
firewalld="$(service firewalld status | grep Active | awk {'print $2'})"
ufw="$(service ufw status | grep Active | awk {'print $2'})"
iptablesubuntu="$(systemctl status iptables | grep "41.185.120.20" | grep -m 1 -o ACCEPT)" 
firewalldubuntu="$(systemctl status firewalld | grep Active | awk {'print $2'})"
ufwubuntu="$(sudo ufw status | grep active | awk {'print $2'})"

# Banner with script information and options
echo -e "\n\n          ${LBLUE}1-${GREY}grid${NOCOL} SNMP service and community configurator\n${YELLOW}################################################################\n##                                                            ##\n## Check SNMP service and add 1-grid communties for Linux     ##\n## Please provide input for one of the following options:     ##\n##                                                            ##\n## 1 - Start Script                                           ##\n## 2 - View Knowledgebase Article                             ##\n## 3 - View Disclaimer                                        ##\n## 4 - Exit Script                                            ##\n##                                                            ##\n################################################################\n\n${NOCOL}"

# Get user input
read -s -p "Please provide option [1 - 4]: " OPTION
 
# Check if input provided is valid, else it will provide more info of the script and request input again
while [[ "$OPTION" != "1" ]] && [[ "$OPTION" != "2"  ]] && [[ "$OPTION" != "3"  ]] && [[ "$OPTION" != "4"  ]]
do
  echo -e "$OPTION\n${RED}Invalid Option\n${YELLOW}Please enter the numer (numeric value) of the option you wish to execute, once the number has been provided the script will prompt you for the following :${NOCOL}\n\n${GREY}1 - Continue to run the script\n2 - View the knowledgebase article\n3 - Exit the script${NOCOL}\n"
  read -s -p "Please provide option [1 - 3] :" OPTION
done

#Welcomer Checker
if [ "$OPTION" == "1" ]
then 

#Perform Distro Check
if [[ $(cat /etc/*-release | head -n1 | awk {'print $1'}) == "CentOS" ]]; 
then 
echo -e "\n\n${YELLOW}**** INFO: DETECTED CENTOS OPERATING SYSTEM ****${NOCOL}\n"
sleep 2

#If running CentOS - performs script below
#Check SNMP service is running already 

if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
then
echo -e "\n\n${YELLOW}**** INFO: PERFORMING COMMUNITY CHECK ****${NOCOL}\n"
sleep 2
	if grep -Fxq "$community1" /etc/snmp/snmpd.conf || grep -Fxq "$community2" /etc/snmp/snmpd.conf
	then
	echo -e "\n\n${LBLUE}**** NOTICE: FOUND 1-GRID COMMUNITY PRESENT ****${NOCOL}\n"
	sleep 2
	
		#Perform Firewall check
		echo -e "\n\n${YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"
		sleep 2
			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
			then
				#Check firewalld 
				if [[ "$firewalld" != "active" ]]
                                then
                                	if [[ "$ufw" != "active" ]]
                                        then
					echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
					fi

				else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"		
				fi
			else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
			sleep 2
			fi
			
		echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
		chkconfig snmpd on &>/dev/null
		service snmpd restart &>/dev/null
	else
		echo -e "\n\n${LBLUE}**** NOTICE: DIDN'T FIND 1-GRID COMMUNITY PRESENT. ADDING COMMUNITY ****${NOCOL}\n"
		echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
		echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
		sleep 2
	fi

else
	echo -e "\n\n${LBLUE}**** NOTICE: DETECTED SNMP SERVICE NOT RUNNING. RESTARTING SERVICE ****${NOCOL}\n"
	service snmpd restart &>/dev/null
	sleep 2

## If service was not active, but now restarted - perform community update ##

	if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
	then	
	echo -e "\n\n${GREEN}**** SUCCESS: SNMP SERVICE IS NOW ACTIVE. PERFORMING COMMUNITY CHECK ****${NOCOL}\n"
	
	if grep -Fxq "$community1" /etc/snmp/snmpd.conf || grep -Fxq "$community2" /etc/snmp/snmpd.conf
	then
		echo -e "\n\n${LBLUE}**** NOTICE: FOUND 1-GRID COMMUNITY PRESENT ****${NOCOL}\n"
                sleep 5

                #Perform Firewall check
                echo -e "\n\n${YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"

			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
                        then
                            	#Check firewalld
                                if [[ "$firewalld" != "active" ]]
                                then
                                    	if [[ "$ufw" != "active" ]]
                                        then
                                        echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
                                        fi

                                else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"                                
				fi
                        else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
                        sleep 5
                        fi



	        echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
                chkconfig snmpd on &>/dev/null
                service snmpd restart &>/dev/null
        else
            	echo -e "\n\n${BLUE}**** NOTICE: DIDN'T FIND 1-GRID COMMUNITY PRESENT. ADDING COMMUNITY ****${NOCOL}\n"
                echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
                echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
                sleep 5
        fi

else
 
	echo -e "\n\n${YELLOW}**** INFO: SNMP SERVICE NOT DETECTED ON THIS SYSTEM. INSTALLING SERVICE ****${NOCOL}\n"
	sleep 5
	yum -y install net-snmp net-snmp-utils 
	echo -e "\n\n${YELLOW}**** INFO: MAKING A BACKUP OF THE SNMP CONF IN THE FOLLOWING PATH - /etc/snmp/snmpd.conf.orig ****${NOCOL}\n"
	mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
	touch /etc/snmp/snmpd.conf
	echo -e "\n\n${YELLOW}**** INFO: ADDING COMMUNITY ****${NOCOL}\n"
        echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
        echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
        sleep 5
	
	echo -e "\n\n{$YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"

			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
                        then
                            	#Check firewalld
                                if [[ "$firewalld" != "active" ]]
                                then
                                    	if [[ "$ufw" != "active" ]]
                                        then
                                        echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
                                        fi

                                else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"                               
			 	fi
                        else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
                        sleep 5
                        fi

                echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
		chkconfig snmpd on &>/dev/null
                service snmpd restart &>/dev/null

fi
fi

#Start of Ubuntu configuration
else
	echo -e "\n\n${YELLOW}**** INFO: DETECTED UBUNTU OPERATING SYSTEM ****${NOCOL}\n"

#If running Ubuntu - performs script below
#Check SNMP service is running already 
#Pop if script isn't being run using su
               if [[ $EUID -ne 0 ]];
                then 
		echo -e "\n\n${YELLOW}**** NOTICE: THIS SCRIPT MUST BE RUN WITH SUDO PRIVILEGE. PLEASE RUN THIS SCRIPT USING `sudo ./snmp_1grid.sh`  ****${NOCOL}\n" 
		exit 1
		else

if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
then
echo -e "\n\n${LBLUE}**** NOTICE: PERFORMING COMMUNITY CHECK ****${NOCOL}\n"
sleep 2
	if grep -Fxq "$community1" /etc/snmp/snmpd.conf || grep -Fxq "$community2" /etc/snmp/snmpd.conf
	then
		echo -e "\n\n${LBLUE}**** NOTICE: FOUND 1-GRID COMMUNITY PRESENT ****${NOCOL}\n"
		sleep 2
	
		#Perform Firewall check
		echo -e "\n\n${YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"
		sleep 2
			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
			then
				#Check firewalld 
				if [[ "$firewalldubuntu" != "active" ]]
                                then
                                	if [[ "$ufwubuntu" != "active" ]]
                                        then
					echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
					fi

				else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"		
				fi
			else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
			sleep 2
			fi
			
		echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
		systemctl enable snmpd.service &>/dev/null
                systemctl start snmpd &>/dev/null

	else
		echo -e "\n\n${LBLUE}**** NOTICE: DIDN'T FIND 1-GRID COMMUNITY PRESENT. ADDING COMMUNITY ****${NOCOL}\n"
		echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
		echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
		sleep 2
	fi

else
	echo -e "\n\n${YELLOW}**** INFO: DETECTED SNMP SERVICE NOT RUNNING. RESTARTING SERVICE ****${NOCOL}\n"
	systemctl restart snmpd &>/dev/null
	sleep 2

## If service was not active, but now restarted - perform community update ##

	if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
	then	
	echo -e "\n\n${GREEN}**** SUCCESS: SNMP SERVICE IS NOW ACTIVE. PERFORMING COMMUNITY CHECK ****{$NOCOL}\n"
	
	if grep -Fxq "$community1" /etc/snmp/snmpd.conf || grep -Fxq "$community2" /etc/snmp/snmpd.conf
	then
		echo -e "\n\n${LBLUE}**** NOTICE: FOUND 1-GRID COMMUNITY PRESENT ****${NOCOL}\n"
                sleep 5

                #Perform Firewall check
                echo -e "\n\n${YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"
			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
                        then
                            	#Check firewalld
                                if [[ "$firewalldubuntu" != "active" ]]
                                then
                                    	if [[ "$ufwubuntu" != "active" ]]
                                        then
                                        echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
                                        fi

                                else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"                                
				fi
                        else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
                        sleep 5
                        fi



	        echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
                systemctl enable snmpd
                systemctl start snmpd
        else
            	echo -e "\n\n${LBLUE}**** NOTICE: DIDN'T FIND 1-GRID COMMUNITY PRESENT. ADDING COMMUNITY ****${NOCOL}\n"
                echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
                echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
                sleep 2
		echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
		 systemctl enable snmpd.service &>/dev/null
                systemctl restart snmpd &>/dev/null	
		sleep 2
        fi

else
 
	echo -e "\n\n${YELLOW}**** INFO: SNMP SERVICE NOT DETECTED ON THIS SYSTEM. INSTALLING SERVICE ****${NOCOL}\n"
	sleep 5
	sudo apt-get install snmpd snmp snmp-mibs-downloader -y
	echo -e "\n\n${YELLOW}**** INFO: MAKING A BACKUP OF THE SNMP CONF ****${NOCOL}\n"
	mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
	touch /etc/snmp/snmpd.conf
	echo -e "\n\n${GREEN}**** INFO: ADDING COMMUNITY ****${NOCOL}\n"
        echo "rocommunity ghspublic default"  >> /etc/snmp/snmpd.conf
        echo "rocommunity6 ghspublic default" >> /etc/snmp/snmpd.conf
        sleep 5
	
	echo -e "\n\n${YELLOW}**** INFO: PERFORMING FIREWALL CHECK ****${NOCOL}\n"

			#Checks the status of the iptables service  - no firewall process monitors iptables by default so checking for process exit code
                        /sbin/service iptables status >/dev/null 2>&1
                        if [ $? != 0 ];
                        then
                            	#Check firewalld
                                if [[ "$firewalldubuntu" != "active" ]]
                                then
                                    	if [[ "$ufwubuntu" != "active" ]]
                                        then
                                        echo -e "\n\n${RED}**** ERROR: WE WERE UNABLE TO FIND YOUR FIREWALL SERVICE. PLEASE MANUALLY ALLOW CONNECTIONS FROM 41.185.120.20 ON PORT 161 (SNMP). MONITORING WON'T BE DONE WITHOUT ADDING THIS RULE MANUALLY. ****${NOCOL}\n"
                                        else
					echo -e "\n\n${LBLUE}**** DETECTED: RUNNING UFW - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n ufw allow from 41.185.120.20 to any port 161 ${NOCOL}\n"
                                        fi

                                else
				echo -e "\n\n${LBLUE}**** DETECTED: RUNNING FIREWALLD - RUN THESE COMMANDS TO ALLOW FIREWALL RULE ****\n firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="41.185.120.20" port protocol="udp" port="161" accept \n firewall-cmd --reload ${NOCOL}\n"                                
				fi
                        else
			echo -e "\n\n${LBLUE}**** DETECTED: RUNNING IPTABLES - RUN THIS COMMAND TO ALLOW FIREWALL RULE ****\n iptables -A INPUT -p udp -s 41.185.120.20 -m state --state NEW -m udp --dport 161 -j ACCEPT ${NOCOL}\n"
                        sleep 5
                        fi

                echo -e "\n\n${YELLOW}**** INFO: FINISHING UP ****${NOCOL}\n"
		systemctl enable snmpd.service &>/dev/null
                systemctl restart snmpd &>/dev/null
	
fi
fi
fi	

fi
#End of Ubuntu Configuration

elif [ "$OPTION" == "2" ]
then
echo -e "$OPTION\n${YELLOW}***** https://support.1-grid.com/support/solutions/articles/33000224234-setup-1-grid-snmp-communities-on-centos-linux- *****\n\n  ${LBLUE}1-${GREY}grid\n    Get online with us${NOCOL}\n"

elif [ "$OPTION" == "3" ]
then
echo -e "$OPTION\n${YELLOW}***** This script comes without warranty of any kind. Use them at your own risk.\n 1-grid assumes no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this script nor for any sort of damages using this script may cause.  *****\n\n  ${LBLUE}1-${GREY}grid\n    Get online with us${NOCOL}\n"

else
  echo -e "$OPTION\n${YELLOW}***** GOOD BYE *****\n\n  ${LBLUE}1-${GREY}grid\n    Get online with us${NOCOL}\n"
  exit 1

fi
