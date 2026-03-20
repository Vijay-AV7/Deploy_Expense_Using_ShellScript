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
        echo -e "$1 $2 .... successfully" 
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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Default nodejs version disabled"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "As requested by developer nodejs version 20 enabled"

VALIDATE nodejs

mkdir -p /app &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "directory app created in /"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Expense backend file from developer downloading"

cd /app &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Changing the pwd to /app"

rm -rf /app/*
PROCESS_VALIDATE $? "Deleting the existing files from /app and loading latest code"

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Unzipping backend file from developer"

npm install &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "npm dependencies installing"

cp /home/ec2-user/Deploy_Expense_Using_ShellScript/BackendService.sh /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "backend service update"

id expense &>>$LOG_FILE_NAME
if [ $? -eq 0 ]
then
    echo -e "User expense exists already"
else
    useradd expense &>>$LOG_FILE_NAME
    PROCESS_VALIDATE $? ""expense" user added"
fi

VALIDATE mysql "mysql"

mysql -h 172.31.15.119 -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Backend Schema loaded"

systemctl daemon-reload &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "backend service enable"

systemctl start backend &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "backend service start"

