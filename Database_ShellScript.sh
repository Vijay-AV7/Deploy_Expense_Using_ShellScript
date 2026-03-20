#!/bin/bash

W="\e[0m" #WHITE
R="\e[31m" #RED
G="\e[32m" #GREEN
Y="\e[33m" #YELLOW

TIMESTAMP_START=$(date)
USER_ID=$(id -u)

# &>> this command will append all the outputs to the log
mkdir -p /var/log/shellscript-logs # this allow to create folder if not exists if exists then it will not create
LOGS_FOLDER="/var/log/shellscript-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE_$TIMESTAMP.log"

VALIDATE () {

    dnf list installed $1 &>>$LOG_FILE_NAME

if [ $? -eq 0 ]
then 
    echo -e "$Y INFORMATION $W:: $1 .... already exists" 
else
    dnf install $1 -y &>>$LOG_FILE_NAME
    if [ $? -eq 0 ]
    then 
        echo -e "$1 $2 .... successful" 
    else    
        echo -e "$R ERROR $W:: $1 $2 .... $R Failure $W"
        exit 1
    fi
fi  
}

PROCESS_VALIDATE () {
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 .... successful" 
    else    
        echo -e "$R ERROR $W:: $2 .... $R Failure $W"
        exit 1
    fi
}

if [ $USER_ID -ne 0 ]
then  
        echo -e "$R ERROR $W:: You must have the sudo access to execute this script"
        exit 1
else 
        echo "$USER user started executing the script at : $TIMESTAMP_START" &>>$LOG_FILE_NAME
        echo "$USER user started executing the script at : $TIMESTAMP_START"
fi

VALIDATE mysql-server "MySql Server installation"

systemctl enable mysqld &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "MySql Server enable"

systemctl start mysqld &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "MySql Server start"

mysql -h 172.31.15.119 -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -eq 0 ]
then  
        echo -e "$Y Root password is already set $W"
else 
        echo -e "Setting up the Root password"
        mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE_NAME
        PROCESS_VALIDATE $? "Root password setup"
fi

systemctl restart mysqld &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "MySql Server restart"


