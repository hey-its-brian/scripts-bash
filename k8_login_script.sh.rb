# This script was purpose-built for the k8 implementation at DCHBX. While it has specific references, it can be adapted fairly easily.

#!/bin/bash

######################################
###   Kubernetes log-in script     ###
###   Author: Brian Meyer (DCHBX)  ###
###   Created: 6/5/2022            ###
###   Last Updated: 06/20/2025     ###
###   Version 2.6 								 ###
######################################
# 2022-12-06: Added additional lower environments and cleaned up spacing, comments, etc.
# This script will log into k8 instances of EA or GDB using bash or irb
# 2023-06-21: Updated spacing a bit and fixed some display typos
# 2023-07-26: Updating PreProd login to include 'container enroll'
# 2024-10-10: Major 2.0 update. This includes:
#				complete rewrite to make script safer to run via printf over exec
#				Added in filtering for system being connected to, so only pods you want show up
#				Complete redo of how case statements work
#				"while true" statements for error handling
#				using variable to execute command instead of exec
#				...and many more tweaks and updates.
# 2025-02-28: Another major update, moving to version 2.5 including:
#				rewrote entire ending sequence to make it easier to read
#				Also made ending a single if statement 
#				Fixed PreProd command creation
# 2025-06-20: Major update to version 2.6.
#				- Upgraded pod selection section to auto-choose the most likely pod
#				- Updated the success message to be Legend of Zelda ASCII
#				- Added version number to top header section
#######################################################################################

# color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#######################################################################################
printf "${BLUE}
    ____  ______   __  ______ _  __
   / __ \/ ____/  / / / / __ ) |/ /
  / / / / /      / /_/ / __  |   / 
 / /_/ / /___   / __  / /_/ /   |  
/_____/\____/  /_/ /_/_____/_/|_|  
                                   ${NC}\n"

printf "${GREEN}
                /|  /|  ${CYAN}------------------------${GREEN}
                ||__||  ${CYAN}|                      |${GREEN}
               /   O O\\__  ${CYAN}Welcome to the k8   |${GREEN}
              /          \\   ${CYAN}Sign-In Wizard    |${GREEN}
             /      \\     \\  ${CYAN}                  |${GREEN}
            /   _    \\     \\ ${CYAN}-------------------${GREEN}
           /    |\\____\\     \\      ${NC}||${GREEN}
          /     | | | |\\____/      ${NC}||${GREEN}
         /       \\| | | |/ |     __${NC}||${GREEN}
        /  /  \\   -------  |_____| ${NC}||${GREEN}
       /   |   |           |       --|
       |   |   |           |_____  --|
       |  |_|_|_|          |     \\----
       /\\                  |
      / /\\        |        /
     / /  |       |       |
 ___/ /   |       |       |
|____/    c_c_c_C/ \\C_c_c_c

version 2.6
${NC}"
#######################################################################################

# Initialization & context listing
printf "\n\n${PURPLE}Current Context: \n${CYAN}-------------------------${NC}\n"
kubectl config current-context
printf "\n"

#########################  Choose Context/NameSpace Section  #########################
printf "${CYAN}Context Choice:
	1 - HBX IT
	2 - PVT-2
	3 - PVT-3
	4 - PVT-4
	5 - PVT-5
	6 - PVT
	7 - PreProd
	8 - PRODUCTION
	0 - Exit
	-----------${NC}\n"

while true; do
	read -p "Context: " context_choice
	# This case statement switches to the proper Context
	case "$context_choice" in
		"1")  # HBX IT
			kubectx dchbx-pvt-eks-cluster
			namespace="hbxit"
			;;
		"2"|"3"|"4"|"5"|"6")  # PVT environments
			kubectx dchbx-pvt-eks-cluster
			namespace="pvt-$((${context_choice}))"
			;;
		"7")
			kubectx dchbx-preprod-eks-cluster
			namespace="preprod"
			;;
		"8")
			kubectx dchbx-prod-eks-cluster
			namespace="prod"
			;;
		"0")
			printf "${RED}Exiting...\n${NC}"
			exit 0
			;;
		*)
			printf "${RED}Invalid input. Please select a valid option.${NC}\n"
			continue
			;;
	esac
	break
done

#########################  Choose System Section  #########################

printf "\n\n${CYAN}System Choice:
	1 - Enroll App
	2 - Glue
	3 - No filtering
	-----------${NC}\n"

# Read the system choice 
read -p "System: " system_choice

# Pod filtering logic based on the system choice
filtered_pods=""

case "$system_choice" in
	"1")
		# Filter pods starting with 'enroll-deploy' for Enroll App
		printf "${GREEN}Listing Enroll App pods...${NC}\n"
		filtered_pods=$(kubectl -n "$namespace" get pods | grep '^enroll-deploy')
		;;
	"2")
		# Determine the correct filter for Glue based on namespace
		case "$namespace" in
			"prod")
				printf "${GREEN}Listing Glue DB pods...${NC}\n"
				filtered_pods=$(kubectl -n "$namespace" get pods | grep '^edidb-prod')
				;;
			"hbxit")
				printf "${GREEN}Listing Glue DB pods...${NC}\n"
				filtered_pods=$(kubectl -n "$namespace" get pods | grep '^edidb-hbxit')
				;;
			"preprod")
				printf "${GREEN}Listing Glue DB pods...${NC}\n"
				filtered_pods=$(kubectl -n "$namespace" get pods | grep '^edidb-preprod')
				;;	
			"pvt"|"pvt-2"|"pvt-3"|"pvt-4"|"pvt-5")
				printf "${GREEN}Listing Glue pods starting with 'edidb-$namespace'...${NC}\n"
				filtered_pods=$(kubectl -n "$namespace" get pods | grep "^edidb-$namespace")
				;;
			*)
				printf "${RED}Invalid namespace for Glue system filtering.${NC}\n"
				exit 1
				;;
		esac
		;;
	"3")
		# No filtering, list all pods
		printf "${GREEN}Listing all pods...${NC}\n"
		filtered_pods=$(kubectl -n "$namespace" get pods)
		;;
	*)
		printf "${RED}Invalid system choice. Please select a valid option.${NC}\n"
		exit 1
		;;
esac
# Try to get the first pod from the filtered list
suggested_pod=$(echo "$filtered_pods" | awk '{print $1}' | head -n1)

printf "${GREEN}
*****************************************************************************
***  Suggested pod: ${CYAN}$suggested_pod${GREEN}
***  Press [Enter] to use this pod
***  Or enter 'n' to choose from the full filtered list
*****************************************************************************
${NC}\n"

read -p "Use suggested pod? (Enter/n): " choice

if [ "$choice" = "n" ] || [ "$choice" = "N" ]; then
	printf "${GREEN}
*****************************************************************************
***  Filtered Pods:
*****************************************************************************
${NC}\n"
	printf "${CYAN}%s\n${NC}" "$filtered_pods"
	read -p "Enter pod name: " podname
else
	podname="$suggested_pod"
	printf "${GREEN}Auto-selected pod: $podname${NC}\n"
fi

# Final safety check before using podname
if [ -z "$podname" ]; then
	printf "${RED}No pod selected. Exiting.${NC}\n"
	exit 1
fi


##############################  Choose Console Section  ##############################

printf "${CYAN}Console Type: 
	  1 - irb
	  2 - bash
	  0 - Exit
	  -------
${NC}\n" 

while true; do
	read -p "Console: " type
	case "$type" in
		"1") 
			console="irb"
			ending="-- bin/rails c"
			break
			;;
		"2") 
			console="bash"
			ending="-- bash"
			break
			;;
		"0") 
			printf "${RED}Exiting...\n${NC}"
			exit 0
			;;
		*)
			printf "${RED}Invalid input. Please select a valid option.${NC}\n"
			;;
	esac
done
echo -e "${GREEN}"
cat << "EOM"

    ⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀
    ⠸⣿⣿⣶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣶⣿⣿⡏
    ⠀⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣿⣿⣿⣿⣿⣿⣿⠁
    ⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⣀⠀⢀⣴⡟⠀⠀⠀⠀⢠⣟⠛⠛⠛⠛⠛⠛⣣⡀⠀⠀⠀⠀⠹⣷⡀⠀⢀⣠⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀
    ⠀⠀⠉⠛⠛⠛⠻⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⣰⣿⣿⣦⠀⠀⠀⠀⣰⣿⣿⣄⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⠛⠛⠛⠉⠁⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠛⠛⠻⠿⣿⣿⡀⠀⠀⣴⣿⣿⣿⣿⣷⡀⠀⣼⣿⣿⣿⣿⣦⠀⠀⠀⣿⣿⡿⠿⠛⠛⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣤⣤⣤⣤⣶⣿⣿⡇⠀⠼⠿⠿⠿⠿⠿⠿⠷⠾⠿⠿⠿⠿⠿⠿⠷⠀⢰⣿⣿⣷⣦⣤⣤⣤⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀
    ⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠉⢁⣹⣿⣿⣿⣶⣄⡀⠀⠀⠀⠀⢠⣆⠀⠀⠀⠀⢀⣠⣴⣿⣿⣿⣿⡀⠉⠙⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠘⣿⣿⠿⠟⠛⠉⠁⠀⠀⣀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⢀⣾⣿⣆⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠉⠛⠻⠿⣿⣿⠇⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⢀⣠⣾⣿⣿⣿⡿⠋⣸⣿⣿⣿⣿⡿⠃⢀⣾⣿⣿⣿⡄⠀⠿⣿⣿⣿⣿⣯⠈⢿⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣿⣿⣿⣿⣿⠋⠀⢠⣿⣿⣿⡏⠀⠀⢀⣼⣿⣿⣿⣿⣷⡀⠀⠀⠘⣿⣿⣿⡆⠀⠙⢿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⠟⠁⠀⠀⣾⣿⣿⣿⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⡿⠂⠀⠀⢿⣿⣿⣿⡀⠀⠀⠙⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠁⠀⠀⠀⣸⣿⣿⣿⡇⠀⢠⣤⡀⠉⢻⣿⣿⣿⠋⠀⣠⣄⠀⠘⣿⣿⣿⣧⠀⠀⠀⠈⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠙⠛⠀⢠⣿⣿⠃⠀⢸⣿⣿⣿⠀⠈⢿⣿⣇⠀⠛⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⠃⠀⠀⢸⣿⣿⣿⠂⠀⠈⢻⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣿⣿⡿⠿⠿⠿⣿⣿⡆⠀⠀⠈⢿⣿⠃⠀⠀⠰⣿⣿⠿⠿⠿⢿⣿⣿⠗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢧⡀⠀⠀⠘⠉⠀⠀⠀⠀⠈⠃⠀⠀⠀⠀⠈⠛⠀⠀⠀⣠⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

               
EOM

echo "               It's dangerous to go alone. Take this. ${NC}

"
echo -e "${NC}"

##############################  Final Command Execution Section  ##############################

# Determine the correct command based on namespace, system choice, and console type
if [ "$namespace" == "preprod" ]; then
	if [ "$system_choice" == "1" ] && [ "$type" == "1" ]; then
		cmd="kubectl exec -ti $podname --container enroll-deploy-tasks -n preprod -- bin/rails c"  # Preprod, Enroll App, IRB
	elif [ "$system_choice" == "1" ] && [ "$type" == "2" ]; then
		cmd="kubectl exec -ti $podname --container enroll-deploy-tasks -n preprod -- bash"  # Preprod, Enroll App, Bash
	elif [ "$system_choice" == "2" ] && [ "$type" == "1" ]; then
		cmd="kubectl exec -ti $podname --container edidb -n $namespace  -- rails c"  # Preprod, Glue, IRB
	elif [ "$system_choice" == "2" ] && [ "$type" == "2" ]; then
		cmd="kubectl exec -ti $podname --container edidb -n $namespace  -- bash"  # Preprod, Glue, Bash
	fi
else
	if [ "$system_choice" == "1" ] && [ "$type" == "1" ]; then
		cmd="kubectl -n $namespace exec -ti $podname  -- bin/rails c"  # Non-Preprod, Enroll App, IRB
	elif [ "$system_choice" == "1" ] && [ "$type" == "2" ]; then
		cmd="kubectl -n $namespace exec -ti $podname  -- bash"  # Non-Preprod, Enroll App, Bash
	elif [ "$system_choice" == "2" ] && [ "$type" == "1" ]; then
		cmd="kubectl exec -ti $podname --container edidb -n $namespace -- rails c"  # Non-Preprod, Glue, IRB
	elif [ "$system_choice" == "2" ] && [ "$type" == "2" ]; then
		cmd="kubectl exec -ti $podname --container edidb -n $namespace -- bash"  # Non-Preprod, Glue, Bash
	fi
fi

# Show and execute the command
printf "${GREEN}$cmd${NC}\n"
$cmd

printf "\n\n"
						#### END ####
