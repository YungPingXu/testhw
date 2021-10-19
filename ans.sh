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
	users=`
		awk -F':' '{if(index($NF, "nologin") == 0){printf $1 " "}}' /etc/passwd | \
		awk -v FS="\n" '{split($1, arr, " ")}END{for(i=1;i<=length(arr);i++){print 1000+i "," arr[i]}}'
	`
	onlineUsers=`who | awk -F" " '{print $1}'`
	para=$(
		for str in $users
		do
			echo "$str" | awk -F"," '{printf $1 " " $2}'
			user=`echo "$str" | awk -F"," '{print $2}'`
			contain=$(echo $onlineUsers | grep "$user")
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
    choice=$(($choice-1000))
    
    tmp=`
    	cat /etc/passwd | grep ":" | grep -v "#" | grep -v "nologin" | \
		awk -F':' '{printf $1 " "}'
	`
	username=$(echo "$tmp" | awk -F"\n" '{split($0,arr," ");print arr['$choice']}')

	result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserVagrant $username
    elif [ $result -eq 1 ] ; then
        Main
    fi
}

Exit(){
    clear
    exit
}

UserVagrant(){
	username=$1
	
    choice=$(dialog --cancel-label "EXIT" \
    --menu "User vagrant" 15 40 10\
    1 "LOCK IT" \
    2 "GROUP INFO" \
    3 "PORT INFO" \
    4 "LOGIN HISTORY" \
    5 "SUDO LOG" \
    2>&1 > /dev/tty)
    
    result=$?
    if [ $result -eq 0 ]; then # 0 means OK, 1 means cancel
        UserVagrantSelect $choice $username
    elif [ $result -eq 1 ] ; then
        UserList
    fi
}

UserVagrantSelect(){
	choice=$1
	username=$2
	clear
    case $choice in
        1) echo option1
        ;;
        2) GroupInfo $username
        ;;
    esac
}

GroupInfo(){
	username=$1
	content=`
		id $username |
		awk '{
			split(substr($NF,8),arr,","); \
			for(i=1;i<=length(arr);i++){ \
				print substr(arr[i], 1, length(arr[i])-1) \
			} \
		}' |
		awk -F"(" '{print $1 " " $2}'
	`
    dialog --title "GROUP" \
    --yes-label "OK" --no-label "EXPORT" \
    --yesno "$content" 15 40
	result=$?
	if [ $result -eq 0 ]; then
		UserVagrant
	elif [ $result -eq 1 ] ; then
		GroupExport $username "$content"
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
		GroupInfo
	elif [ $result -eq 1 ] ; then
		GroupInfo
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
    dialog --title "POST ANNOUNCEMENT" \
    --inputbox "Enter your messages:" 10 40 
}

LockIt(){
    dialog --title "LOCK IT" \
    --yesno "Are you sure you want to do this?" 15 40
}

LockSucceed(){
    dialog --title "LOCK IT" \
    --msgbox "LOCK SUCCEED!" 15 40
}

PortInfo(){
    dialog --title "Port INFO(PID and Port)" \
    --menu "" 10 40 2 \
    134 "tcp1" \
    222 "tcp2"
}

LoginHistory(){
    dialog --title "LOGIN HISTORY" \
    --yes-label "OK" --no-label "EXPORT" \
    --yesno "content" 15 40
}

SudoLog(){
    dialog --title "SUDOLOG" \
    --yes-label "OK" --no-label "EXPORT" \
    --yesno "content" 15 40
}

ProcessState(){
    dialog --title "PROCESS STATE: 2409" \
    --yes-label "OK" --no-label "EXPORT" \
    --yesno "content" 15 40
}

Main