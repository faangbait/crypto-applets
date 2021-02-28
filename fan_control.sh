#!/bin/bash

HYSTERESIS=6000   # in mK
SLEEP_INTERVAL=1  # in s
DEBUG=true

# set temps (in degrees C * 1000) and corresponding pwm values in ascending order and with the same amount of values
TEMPS=( 40000 56000 65000 75000 80000 85000 )
PWMS=(   20     90   128   180   230   255 )

# hwmon paths, hardcoded for one amdgpu card, adjust as needed
FILE_PWM=$(echo /sys/class/drm/card0/device/hwmon/hwmon?/pwm1)
FILE_FANMODE=$(echo /sys/class/drm/card0/device/hwmon/hwmon?/pwm1_enable)
FILE_TEMP=$(echo /sys/class/drm/card0/device/hwmon/hwmon?/temp1_input)
FILE_TEMP3=$(echo /sys/class/drm/card0/device/hwmon/hwmon?/temp3_input)
# might want to use this later
#FILE_TEMP_CRIT=$(echo /sys/class/hwmon/hwmon?/temp1_crit_hyst)

# load configuration file if present
[ -f /etc/amdgpu-fancontrol.cfg ] && . /etc/amdgpu-fancontrol.cfg

[[ -f "$FILE_PWM" && -f "$FILE_FANMODE" && -f "$FILE_TEMP" && -f "$FILE_TEMP3" ]] || { echo "invalid hwmon files" ; exit 1; }

# check if amount of temps and pwm values match
if [ "${#TEMPS[@]}" -ne "${#PWMS[@]}" ]
then
  echo "Amount of temperature and pwm values does not match"
  exit 1
fi

# checking for privileges
if [ $UID -ne 0 ]
then
  echo "Writing to sysfs requires privileges, relaunch as root"
  exit 1
fi

function debug {
  if $DEBUG; then
    echo $1
  fi
}

# set fan mode to max(0), manual(1) or auto(2)
function set_fanmode {
  echo "setting fan mode to $1"
  echo "$1" > "$FILE_FANMODE"
}

function set_pwm {
  NEW_PWM=$1
  OLD_PWM=$(cat $FILE_PWM)

  debug "current pwm: $OLD_PWM, requested to set pwm to $NEW_PWM"
  if [ $(cat ${FILE_FANMODE}) -ne 1 ]
  then
    echo "Fanmode not set to manual."
    set_fanmode 1
  fi

  if [ -z "$TEMP_AT_LAST_PWM_CHANGE" ] || [ "$TEMP" -gt "$TEMP_AT_LAST_PWM_CHANGE" ] || [ $(( ( $(cat $FILE_TEMP)>$(cat $FILE_TEMP3)? $(cat $FILE_TEMP) : $(cat $FILE_TEMP3) ) + HYSTERESIS)) -le "$TEMP_AT_LAST_PWM_CHANGE" ]; then
    $DEBUG || echo "current temp: $TEMP"
    echo "temp at last change was $TEMP_AT_LAST_PWM_CHANGE"
    echo "changing pwm to $NEW_PWM"
    echo "$NEW_PWM" > "$FILE_PWM"
    TEMP1_AT_LAST_PWM_CHANGE=$(cat $FILE_TEMP)
    TEMP3_AT_LAST_PWM_CHANGE=$(cat $FILE_TEMP3)
    TEMP_AT_LAST_PWM_CHANGE=$(( $TEMP1 > $TEMP3 ? $TEMP1 : $TEMP3 ))
  else
    debug "not changing pwm, we just did at $TEMP_AT_LAST_PWM_CHANGE, next change when below $((TEMP_AT_LAST_PWM_CHANGE - HYSTERESIS))"
  fi
}

function interpolate_pwm {
  i=0
  TEMP1=$(cat $FILE_TEMP)
  TEMP3=$(cat $FILE_TEMP3)
  TEMP=$(( $TEMP1 > $TEMP3 ? $TEMP1 : $TEMP3 ))

  debug "current temp: $TEMP"

  if [[ $TEMP -le ${TEMPS[0]} ]]; then
    # below first point in list, set to min speed
    set_pwm "${PWMS[i]}"
    return
  elif [[ $TEMP -gt ${TEMPS[-1]} ]]; then
    # above last point in list, set to max speed
    set_pwm "${PWMS[-1]}"
    return
  fi

  for i in "${!TEMPS[@]}"; do
    if [[ $TEMP -gt ${TEMPS[$i]} ]]; then
      continue
    fi

    # interpolate linearly
    LOWERTEMP=${TEMPS[i-1]}
    HIGHERTEMP=${TEMPS[i]}
    LOWERPWM=${PWMS[i-1]}
    HIGHERPWM=${PWMS[i]}
    PWM=$(echo "( ( $TEMP - $LOWERTEMP ) * ( $HIGHERPWM - $LOWERPWM ) / ( $HIGHERTEMP - $LOWERTEMP ) ) + $LOWERPWM" | bc)
    debug "interpolated pwm value for temperature $TEMP is: $PWM"
    set_pwm "$PWM"
    return
  done
}

function reset_on_exit {
  echo "exiting, resetting fan to auto control..."
  set_fanmode 2
  exit 0
}

# always try to reset fans on exit
trap "reset_on_exit" SIGINT SIGTERM

function run_daemon {
  while :; do
    interpolate_pwm
    debug
    sleep $SLEEP_INTERVAL
  done
}

# set fan control to manual
set_fanmode 1

# finally start the loop
run_daemon

