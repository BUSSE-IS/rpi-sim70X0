#!/bin/sh

while true; do

        ping -I ppp0 -c 1 8.8.8.8 -s 0
        i=0
        if [ $? -eq 0 ]; then
                echo "Connection up, reconnect not required..."
                i=0
        else
                echo "Connection down, reconnecting..."
                if [ $i -lt 5 ]; then
                        sudo ifconfig wwan0 down
                        sudo pon
                else
                        sudo ifconfig wwan0 down
                        gpio mode 4 out
                        gpio write 4 1
                        sleep 1.5
                        gpio write 4 0
                        sleep 10
                        gpio write 4 1
                        sleep 0.3
                        gpio write 4 0
                        sleep 10
                        sudo pon
                fi
                i++
        fi
        sleep 10
done
