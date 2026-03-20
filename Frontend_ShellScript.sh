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
LOG_FILE=$(echo "$0" | cut -d "." -f1 )
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

VALIDATE nginx "Installation"

systemctl enable nginx &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "nginx service enable"

systemctl start nginx &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "nginx service start"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Removed existing code from Nginx HTML directory"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Downloading Frontend code from developer"

cd /usr/share/nginx/html &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Changing the pwd to /usr/share/nginx/html"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Unzipping frontend code from developer"

cp /home/ec2-user/Deploy_Expense_Using_ShellScript/Frontend_Config.sh /etc/nginx/default.d/expense.conf &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "Copying Frontend configuration to expense.conf"

systemctl restart nginx &>>$LOG_FILE_NAME
PROCESS_VALIDATE $? "nginx service restart"