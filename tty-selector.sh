#!/bin/bash

echo "Detecting serial devices..."
devices=$(find /dev -name 'ttyS*' -or -name 'ttyUSB*' -or -name 'ttyACM*' 2>/dev/null)

if [ -z "$devices" ]; then
    echo "No serial devices found."
    exit 1
fi

device_info=()  # Array to hold device descriptions

# Gather information about devices
for device in $devices; do
    desc=$(udevadm info --name=$device --query=property | grep -e 'ID_SERIAL_SHORT' -e 'ID_VENDOR_ID' -e 'ID_MODEL_ID' -e 'ID_MODEL=')
    manufacturer=$(echo "$desc" | grep 'ID_VENDOR=' | cut -d '=' -f2)
    model=$(echo "$desc" | grep 'ID_MODEL=' | cut -d '=' -f2)
    serial=$(echo "$desc" | grep 'ID_SERIAL_SHORT=' | cut -d '=' -f2)

    if [[ -n "$manufacturer" && -n "$model" ]]; then
        device_info+=("$device ($manufacturer $model - $serial)")
    else
        device_info+=("$device (Unknown Device)")
    fi
done

# Display a menu for device selection
echo "Available serial devices:"
select device_entry in "${device_info[@]}"; do
    if [[ -n "$device_entry" ]]; then
        # Extract the device path from the selected entry
        device_path=$(echo "$device_entry" | cut -d ' ' -f1)
        echo "You selected: $device_entry"
        break
    else
        echo "Invalid selection, please try again."
    fi
done

# Read baud rate from user
read -p "Enter the baud rate [default 9600]: " baud_rate
baud_rate=${baud_rate:-9600}

if ! [[ "$baud_rate" =~ ^[0-9]+$ ]]; then
    echo "Invalid baud rate entered. Using default 9600."
    baud_rate=9600
fi
echo "Connecting to $device_path at $baud_rate baud..."
