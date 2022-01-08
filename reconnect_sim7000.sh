#!/bin/sh

while true; do
        i=0
        ping -I ppp0 -c 1 8.8.8.8 -s 0
        if [ $? -eq 0 ]; then
                echo "Connection up, reconnect not required..."
                i=0
        else
                echo "Connection down, reconnecting..."
                if [ $i -lt 5 ]; then
                        sudo ifconfig wwan0 down
                        sudo pon
                elif [ $i -ge 5 ] && [ $i -lt 8 ]; then
                        echo AT+CPOWD=1 | socat - /dev/ttyUSB3,crnl
                        sleep 5
                        sudo ifconfig wwan0 down
                        sudo pon
                else
                        echo AT+CPOWD=1 | socat - /dev/ttyUSB3,crnl
                        sleep 5
                        gpio write 4 1
                        sleep 2
                        gpio write 4 0
                        sleep 10
                        sudo ifconfig wwan0 down
                        sudo pon
                fi
                i = i+1
        fi
        sleep 10
done
