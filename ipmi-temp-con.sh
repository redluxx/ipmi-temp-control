# Fan speed control through ipmi
# IPMI control must be set to administrator inside iDrac and enabled. (To confirm other roles)
# Log in > iDrac Settings > Network/Secruity > Scroll down to IPMI Settings
# For dynamic management run as a service or always on host.

# Command to see fan speeds
# ipmitool -I lanplus -H IPADDRESS -U USER -P PASSWORD sdr type fan

# root & clavin are iDrac6 default credentials 
# IPMI SETTINGS:
R210=IPADDRESS
IPMIUSER=root
IPMIPW=calvin

# TEMPERATURE
# If the temperature goes above the set degrees it will send raw IPMI command to enable dynamic fan control

R210MAXTEMP=30
R210WARNTEMP=27

# This variable sends a IPMI command to get the temperature, and outputs it as two digits.
R210TEMP=$(ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW sdr get "Inlet Temp" | grep "Sensor Reading" | awk '{print $4}')

# R210 Fan Speeds
# 0x22 5880rpm - clear noise
# 0x21 5760rpm
# 0x20 5520rpm - Audiable
# 0x1F 5400rpm
# 0x1E 5280rpm
# 0x1D 5040rpm
# 0x1C 4920rpm
# 0x1B 4560rpm

# Disables manual control of the fans (usefull when system is breaching max temp var
# ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x01

# Enables manual control of the fans ( to be followed by another command to set the fan speed
# ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x00

# If manual fan speed enabled then this will set the fans to 5520rpm
# ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x02 0xff 0x20


if [[ $R210TEMP > $R210MAXTEMP ]];
  then
    #echo "R210 Temperature is BAD ($R210TEMP C)"
    printf "R210 Temperature is BAD ($R210TEMP C)" | systemd-cat -t IPMI-TEMP
    ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x01

elif [[ $R210TEMP > $R210WARNTEMP ]];
  then
    #echo "R210 Temperature is WARN ($R210TEMP c)"
    printf "R210 Temperature is WARN ($R210TEMP C)" | systemd-cat -t IPMI-TEMP
    ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x00
    ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x02 0xff 0x20

else
    #echo "R210 Temperature is OK ($R210TEMP C)"
    printf "R210 Temperature is OK ($R210TEMP C)" | systemd-cat -t IPMI-TEMP
    ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x01 0x00
    ipmitool -I lanplus -H $R210 -U $IPMIUSER -P $IPMIPW raw 0x30 0x30 0x02 0xff 0x1E
fi
