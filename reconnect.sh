function restart_power()
{
	print "Power of the module is restarting..."
	# Restart power
	sudo ifconfig wwan0 down
        gpio mode 7 out
        gpio -g write 7 1
        sleep 1.5
        gpio -g write 7 0
        sleep 10
        gpio -g write 7 1
        sleep 0.3
        gpio -g write 7 0
        sleep 10
}
i=0
while true; do
    # Checking cellular internet connection
    ping -q -c 1 -s 0 -w $PING_TIMEOUT -I ppp0 8.8.8.8 > /dev/null 2>&1
    PINGG=$?

    if [[ $PINGG -eq 0 ]]; then
        echo "."
	i=0
    else
        echo "/"
        sleep 10
	    # Checking cellular internet connection
        ping -q -c 1 -s 0 -w $PING_TIMEOUT -I ppp0 8.8.8.8 > /dev/null 2>&1
        PINGG=$?

        if [[ $PINGG -eq 0 ]]; then
            echo "+"
	    i=0
        elif [[ $PINGG -ne 0 ]] && [[ $i -le 10 ]]; then
	    echo "Connection is down, reconnecting..."
	    sudo poff
	    restart_power
	    sudo ifconfig wwan0 down
	    sudo pon
	    sudo /etc/init.d/rinetd restart
			
	    # check default interface
	    route | grep ppp | grep default > /dev/null
	    PPP_IS_DEFAULT=$?
	    if [[ $PPP_IS_DEFAULT -ne 0 ]]; then sudo route add default ppp0; echo "ppp0 is added as default interface manually."; fi
	    ((i=i+1))
	elif [[ $PINGG -ne 0 ]] && [[ $i -gt 10 ]]; then
	    echo "Reboot indicated because too many reconnect failures."
	    sleep 5
	    sudo shutdown -r now
	fi
    fi
    sleep 60
done
