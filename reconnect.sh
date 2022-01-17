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
        print "."
	i=0
    else
        print "/"
        sleep 10
	    # Checking cellular internet connection
        ping -q -c 1 -s 0 -w $PING_TIMEOUT -I ppp0 8.8.8.8 > /dev/null 2>&1
        PINGG=$?

        if [[ $PINGG -eq 0 ]]; then
            print "+"
	    i=0
        elif [[ $PINGG -eq 0 ]] && [[ $i -le 10 ]]; then
	    print "Connection is down, reconnecting..."      
	    restart_power
	    sudo pon
	    sudo /etc/init.d/rinetd start
			
	    # check default interface
	    route | grep ppp | grep default > /dev/null
	    PPP_IS_DEFAULT=$?
	    if [[ $PPP_IS_DEFAULT -ne 0 ]]; then sudo route add default ppp0; print "ppp0 is added as default interface manually."; fi
	    ((i=i+1))
	elif [[ $PINGG -eq 0 ]] && [[ $i -gt 10 ]]; then
	    print "Reboot indicated because too many reconnect failures."
	    sudo shutdown -r now
	fi
    fi
    sleep 60
done