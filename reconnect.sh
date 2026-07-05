function set_power_pin()
{
        # SIM module power key is BCM GPIO 4 (= WiringPi pin 7).
        # Prefer pinctrl (ships with Raspberry Pi OS Bookworm/Trixie);
        # fall back to the legacy WiringPi gpio binary on older devices.
        if command -v pinctrl > /dev/null 2>&1; then
                if [ "$1" = "1" ]; then
                        pinctrl set 4 op dh
                else
                        pinctrl set 4 op dl
                fi
        else
                gpio mode 7 out
                gpio write 7 "$1"
        fi
}
function restart_power()
{
        echo "Power of the module is restarting..."
        # Restart power
        sudo ifconfig wwan0 down
        set_power_pin 1
        sleep 1.5
        set_power_pin 0
        sleep 10
        set_power_pin 1
        sleep 0.3
        set_power_pin 0
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
        elif [[ $PINGG -ne 0 ]] && [[ $i -le 30 ]]; then
            echo "Connection is down, reconnecting..."
            sudo poff
            restart_power
            # timeout: pppd (persist+updetach) can otherwise block here forever
            # and the reboot fallback below would never be reached
            sudo timeout 300 pon
            # try-restart: only restart rinetd if it is running; the old
            # 'init.d restart' started rinetd on every boot even when disabled
            sudo systemctl try-restart rinetd
            ((i=i+1))
        elif [[ $PINGG -ne 0 ]] && [[ $i -gt 30 ]]; then
            echo "Reboot indicated because too many reconnect failures."
            sleep 5
            sudo shutdown -r now
        fi
    fi
    sleep 180
done
