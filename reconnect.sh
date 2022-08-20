function restart_power()
{
        echo "Power of the module is restarting..."
        # Restart power
        sudo ifconfig wwan0 down
        gpio mode 7 out
        gpio write 7 1
        sleep 1.5
        gpio write 7 0
        sleep 10
        gpio write 7 1
        sleep 0.3
        gpio write 7 0
        sleep 10
}
i=0
while true; do
    # Checking cellular internet connection
    ping -q -c 1 -s 0 -w 2 -I ppp0 8.8.8.8 > /dev/null 2>&1
    PINGG=$?

    if [[ $PINGG -eq 0 ]]; then
        echo "."
        i=0
    else
        echo "/"
        sleep 2
            # Checking cellular internet connection again
        ping -q -c 1 -s 0 -w 2 -I ppp0 8.8.8.8 > /dev/null 2>&1
        PINGG=$?

        if [[ $PINGG -eq 0 ]]; then
            echo "+"
            i=0
        elif [[ $PINGG -ne 0 ]] && [[ $i -le 15 ]]; then
            echo "Connection is down, reconnecting..."
            sudo poff
            restart_power
            sudo pon
            sudo /etc/init.d/rinetd restart
            ((i=i+1))
        elif [[ $PINGG -ne 0 ]] && [[ $i -gt 15 ]]; then
            echo "Reboot indicated because too many reconnect failures."
            sleep 5
            sudo shutdown -r now
        fi
    fi
    sleep 120
done
