#!/bin/sh

trap "detectCtrlC" 2

height=20
width=50
menuHeight=10

detectCtrlC(){
	clear
	echo "Ctrl + C pressed."
	exit 2
}

detectESC(){
	clear
	echo >&2 "Esc pressed."
	exit
}

Exit(){
    clear
    echo "Exit."
    exit
}

Main(){
    selection=$(dialog --title "System Info Panel" \
	--menu "Please select the command you want to use" $height $width $menuHeight \
	1 "POST ANNOUNCEMENT" \
	2 "USER LIST" \
	2>&1 > /dev/tty)

    result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        MainSelect $selection
    elif [ $result -eq 1 ] ; then
        Exit
    elif [ $result -eq 255 ] ; then
		detectESC
    fi
}

MainSelect(){
	choice=$1
	clear
    case $choice in
        1) PostAnnouncement
        ;;
        2) UserList
        ;;
    esac
}

PostAnnouncement(){
	allUsers=`
		cat /etc/passwd | grep ":" | grep -v "#" | grep -v "nologin" | \
		awk -F":" '{print 1000+NR " " $1 " off"}'
	`
    selection=$(dialog --title "POST ANNOUNCEMENT" \
    --checklist "Please choose who you want to post" $height $width $menuHeight $allUsers \
    2>&1 > /dev/tty)
	result=$?
    selectedUsers=$(
		for str in $selection
		do
			line=$(echo "$allUsers" | grep "$str")
			if [ "$line" != "" ] ; then
				echo $line | awk '{print $2}'
			fi
    	done
    )
	if [ $result -eq 0 ]; then
		SendMessages "$selectedUsers"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
		Main
	fi 
}

SendMessages(){
	users=$1
	exec 3>&1
    input=$(dialog --title "Post an announcement" --inputbox "Enter your messages:" $height $width 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		mesg y
		for user in $users
		do
			echo "$input" | write "$user"
		done
	fi
	Main
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
    --menu "User Info Panel" $height $width $menuHeight $para \
    2>&1 > /dev/tty)
	result=$?
	username=$(echo "$allUsers" | grep "$choice" | awk -F"," '{print $2}')
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserPanel "$username"
    elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
        Main
    fi
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
    --menu "User $username" $height $width $menuHeight \
    1 "$option1" \
    2 "GROUP INFO" \
    3 "PORT INFO" \
    4 "LOGIN HISTORY" \
    5 "SUDO LOG" \
    2>&1 > /dev/tty)
    
    result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserPanelSelect $choice "$username" "$option1"
    elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
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
	para=$(sockstat -4 | grep "$username" | awk '{print $3 " " $5 "_" $6}')
    choice=$(dialog --title "Port INFO(PID and Port)" \
    --menu "" $height $width $menuHeight $para \
    2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        ProcessState "$username" "$choice"
    elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
        UserPanel "$username"
    fi
}

ProcessState(){
	username=$1
	PID=$2
	content=$(
		echo "USER $username"
		ps aux | awk '{ \
			if($1 == "'$username'" && $2 == "'$PID'"){ \
				print "PID " $2 "\nSTAT " $8 "\n%CPU " $3 "\n%MEM " $4 "\nCOMMAND " $NF
			}
		}'
	)
    dialog --title "PROCESS STATE: $PID" --yes-label "OK" --no-label "EXPORT" --yesno "$content" $height $width
    result=$?
	if [ $result -eq 0 ] || [ $result -eq 255 ] ; then
		PortInfo "$username"
	elif [ $result -eq 1 ] ; then
		PSExport "$username" "$content" "$PID"
	fi
}

PSExport(){
	username=$1
	content=$2
	PID=$3
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" $height $width 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		ProcessState "$username" "$PID"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
		ProcessState "$username" "$PID"
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
    dialog --title "LOGIN HISTORY" --yes-label "OK" --no-label "EXPORT" --yesno "$content" $height $width
    result=$?
	if [ $result -eq 0 ] || [ $result -eq 255 ] ; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		LoginHistoryExport "$username" "$content"
	fi
}

LoginHistoryExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" $height $width 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		LoginHistory "$username"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
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
    dialog --title "SUDO LOG" --yes-label "OK" --no-label "EXPORT" --yesno "$content" $height 80
    result=$?
	if [ $result -eq 0 ] || [ $result -eq 255 ] ; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		SudoExport "$username" "$content"
	fi
}

SudoExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" $height $width 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		echo "$content" > "$input"
		SudoLog "$username"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
		SudoLog "$username"
	fi
}

LockorUnlock(){
	username=$1
	lockoption=$2
    dialog --title "$lockoption" --yesno "Are you sure you want to do this?" $height $width
    result=$?
	if [ $result -eq 0 ]; then
		if [ "$lockoption" = "LOCK IT" ] ; then
			pw lock "$username"
		else
			pw unlock "$username"
		fi
		LockorUnlockSucceed "$username" "$lockoption"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
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
    dialog --title "$lockoption" --msgbox "$message" $height $width
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
    dialog --title "GROUP" --yes-label "OK" --no-label "EXPORT" --yesno "$content" $height $width
	result=$?
	if [ $result -eq 0 ] || [ $result -eq 255 ] ; then
		UserPanel "$username"
	elif [ $result -eq 1 ] ; then
		GroupExport "$username" "$content"
	fi
}

GroupExport(){
	username=$1
	content=$2
	exec 3>&1
    input=$(dialog --title "Export to file" --inputbox "Enter the path:" $height $width 2>&1 1>&3)
    result=$?
    exec 3>&-
	if [ $result -eq 0 ]; then
		#tmp=$(echo $input | cut -c1)
		#if [ $tmp = "~" ] ; then
		#	replace=$(echo "$input" | sed "s/^.\(.*\)/\1/")
		#	home=$(grep "$username" /etc/passwd | awk -F":" '{print $(NF-1)}')
		#	path=$(echo $home$replace)
		#else
		#	path=$input
		#fi
		echo "$content" > "$input"
		GroupInfo "$username"
	elif [ $result -eq 1 ] || [ $result -eq 255 ] ; then
		GroupInfo "$username"
	fi
	
}

Main