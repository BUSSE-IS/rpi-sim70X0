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
function link_ok()
{
    # One 28-byte probe, 5 s deadline. The old 2 s deadline was below the
    # latency this link normally shows (MQTT PINGRESP round trips of 3 s are
    # routine on NB-IoT), so ordinary jitter was being read as a dead link.
    ping -q -c 1 -s 0 -w 5 -I ppp0 8.8.8.8 > /dev/null 2>&1 && return 0
    # second target: a single unreachable anycast destination must not be
    # enough to power-cycle the modem
    ping -q -c 1 -s 0 -w 5 -I ppp0 1.1.1.1 > /dev/null 2>&1
}
i=0
while true; do
    # Checking cellular internet connection. Three rounds spread over ~30 s
    # before declaring the link dead: a poff + modem power cycle costs a ~2 min
    # outage and a full TLS reconnect, so it must not fire on packet loss.
    # Data cost is unchanged while the link is healthy - the extra rounds only
    # run when a probe has already failed.
    if link_ok; then
        echo "."
        i=0
    else
        echo "/"
        sleep 15
        if link_ok; then
            echo "+"
            i=0
        else
            echo "/"
            sleep 15
            if link_ok; then
                echo "+"
                i=0
            elif [[ $i -le 30 ]]; then
                echo "Connection is down after 3 probe rounds, reconnecting..."
                sudo poff
                restart_power
                # timeout: pppd (persist+updetach) can otherwise block here
                # forever and the reboot fallback below would never be reached
                sudo timeout 300 pon
                # try-restart: only restart rinetd if it is running; the old
                # 'init.d restart' started rinetd on every boot even when disabled
                sudo systemctl try-restart rinetd
                ((i=i+1))
            else
                echo "Reboot indicated because too many reconnect failures."
                sleep 5
                sudo shutdown -r now
            fi
        fi
    fi
    sleep 180
done
