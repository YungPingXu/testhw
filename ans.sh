#!/bin/sh

Main(){
    selection=$(dialog --title "System Info Panel" \
	--menu "Please select the command you want to use" 10 50 2 \
	1 "POST ANNOUNCEMENT" \
	2 "USER LIST" \
	2>&1 > /dev/tty)

    result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        MainSelect $selection
    elif [ $result -eq 1 ] ; then
        Exit
    fi
}

MainSelect(){
	choice=$1
	clear
    case $choice in
        1) echo option1
        ;;
        2) UserList
        ;;
    esac
}

UserList(){
	allUsers=`
		cat /etc/passwd | grep ":" | grep -v "#" | grep -v "nologin" | \
		awk -F":" '{print 1000+NR "," $1}'
	`
	onlineUsers=`who | awk -F" " '{print $1}'`
	para=$(
		for str in $allUsers
		do
			echo "$str" | awk -F"," '{printf $1 " " $2}'
			user=`echo "$str" | awk -F"," '{print $2}'`
			contain=$(echo "$onlineUsers" | grep "$user")
			if [ "$contain" != "" ] ; then
				echo "[*]"
			else
				echo
			fi
		done
	)
    choice=$(dialog --cancel-label "EXIT" --ok-label "SELECT" \
    --menu "User Info Panel" 15 40 10 $para \
    2>&1 > /dev/tty)
	result=$?
	username=$(echo "$allUsers" | grep "$choice" | awk -F"," '{print $2}')
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserPanel "$username"
    elif [ $result -eq 1 ] ; then
        Main
    fi
}

Exit(){
    clear
    exit
}

UserPanel(){
	username=$1
	contain=$(grep "$username" /etc/master.passwd | grep "*LOCKED*")
	if [ "$contain" != "" ] ; then
		option1="UNLOCK IT"
	else
		option1="LOCK IT"
	fi
    choice=$(dialog --cancel-label "EXIT" \
    --menu "User $username" 15 40 10\
    1 "$option1" \
    2 "GROUP INFO" \
    3 "PORT INFO" \
    4 "LOGIN HISTORY" \
    5 "SUDO LOG" \
    2>&1 > /dev/tty)
    
    result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserPanelSelect $choice "$username" "$option1"
    elif [ $result -eq 1 ] ; then
        UserList
    fi
}

UserPanelSelect(){
	choice=$1
	username=$2
	lockoption=$3
	clear
    case $choice in
        1) LockorUnlock "$username" "$lockoption"
        ;;
        2) GroupInfo "$username"
        ;;
        3) PortInfo "$username"
        ;;
        4) LoginHistory "$username"
        ;;
        5) SudoLog "$username"
        ;;
    esac
}

PortInfo(){
	username=$1
	content=$(
		sockstat -4 | grep "$username" | awk '{print $3 " " $5 "_" $6}'
	)
    choice=$(dialog --title "Port INFO(PID and Port)" \
    --menu "Port INFO(PID and Port)" 10 40 10 "$content" \
    2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserPanel "$username"
    elif [ $result -eq 1 ] ; then
        UserPanel "$username"
    fi
}

LoginHistory(){
	username=$1
	content=$(
		echo "DATE IP"
		last "$username" | \
		grep -oE '.*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*' | \
		awk '{print $4 " " $5 " " $6 " " $7 " " $3}'
	)
    dialog --title "LOGIN HISTORY" --yes-label "OK" --no-label "EXPORT" --yesno "$content" 15 40
    result=$?
	if [ $result -eq 0 ]; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		LoginHistoryExport "$username" "$content"
	fi
}

LoginHistoryExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 40 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		LoginHistory "$username"
	elif [ $result -eq 1 ] ; then
		LoginHistory "$username"
	fi
}

SudoLog(){
	username=$1
	authlog=$(
		cat /var/log/auth.log | grep -E "sudo|COMMAND=" | \
		awk -F" : |;" '{for(i=1;i<NF;i++) printf $i ";"; print $NF;}' | \
		awk -F";" '{print $1 " " $NF;}' | \
		awk -F"COMMAND=" '{print $1 " " $2}' | \
		awk '{if($6=="'$username'"){ \
			printf $6 " used sudo to do `"; \
			for(i=7;i<NF;i++) printf $i " "; \
			print $NF "` on " $1 " " $2 " " $3
		}}'
	)
	content=$(
		echo "$authlog" | while read -r line;
		do
			myDate=$(echo "$line" | awk '{print $(NF-2) " " $(NF-1) " " $(NF)}')
			currentTime=$(date "+%s")
			dateTime=$(date -j -f "%b %d %T" "$myDate" "+%s")
			timeDiff=`expr $currentTime - $dateTime`
			dayDiff=`expr $timeDiff / 86400`
			if [ $dayDiff -lt 15 ] ; then
				echo $line
			fi
		done
	)
    dialog --title "SUDO LOG" --yes-label "OK" --no-label "EXPORT" --yesno "$content" 15 100
    result=$?
	if [ $result -eq 0 ]; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		SudoExport "$username" "$content"
	fi
}

SudoExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 40 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		SudoLog "$username"
	elif [ $result -eq 1 ] ; then
		SudoLog "$username"
	fi
}

LockorUnlock(){
	username=$1
	lockoption=$2
    dialog --title "$lockoption" --yesno "Are you sure you want to do this?" 15 40
    result=$?
	if [ $result -eq 0 ]; then
		if [ "$lockoption" = "LOCK IT" ] ; then
			pw lock "$username"
		else
			pw unlock "$username"
		fi
		LockorUnlockSucceed "$username" "$lockoption"
	elif [ $result -eq 1 ] ; then
		UserPanel "$username" "$lockoption"
	fi
}

LockorUnlockSucceed(){
	username=$1
	lockoption=$2
	if [ "$lockoption" = "LOCK IT" ] ; then
		message="LOCK SUCCEED!"
	else
		message="UNLOCK SUCCEED!"
	fi
    dialog --title "$lockoption" --msgbox "$message" 15 40
    UserPanel "$username"
}

GroupInfo(){
	username=$1
	content=`
		echo "GROUP_ID GROUP_NAME"
		id $username |
		awk '{
			split(substr($NF,8),arr,","); \
			for(i=1;i<=length(arr);i++){ \
				print substr(arr[i], 1, length(arr[i])-1) \
			} \
		}' |
		awk -F"(" '{print $1 " " $2}'
	`
    dialog --title "GROUP" --yes-label "OK" --no-label "EXPORT" --yesno "$content" 15 40
	result=$?
	if [ $result -eq 0 ]; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		GroupExport "$username" "$content"
	fi
}

GroupExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 40 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		GroupInfo "$username"
	elif [ $result -eq 1 ] ; then
		GroupInfo "$username"
	fi
}

PostAnnouncement(){
    dialog --title "POST ANNOUNCEMENT" \
    --checklist "Please choose who you want to post" 15 40 2 \
    1 "user1" off \
    2 "user2" on \
    3 "user3" on
}

TypeMessage(){
    dialog --title "POST ANNOUNCEMENT" --inputbox "Enter your messages:" 10 40 
}

ProcessState(){
    dialog --title "PROCESS STATE: 2409" --yes-label "OK" --no-label "EXPORT" --yesno "content" 15 40
}

Main