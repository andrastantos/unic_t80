#!/usr/bin/python

from pylibftdi import BitBangDevice
import pylibftdi
from time import sleep

device_list = pylibftdi.Driver().list_devices()
for vendor, product, serial in pylibftdi.Driver().list_devices():
    print(f"{vendor}:{product}:{serial}")

#if len(device_list) > 1:
#    print("More than one FTDI device is attached. Refusing to work!")
#    exit(1)

#with BitBangDevice(interface_select=pylibftdi.INTERFACE_B) as bb:
with BitBangDevice(device_id="FT232R USB UART") as bb:
    bb.port = 1
    bb.direction = 0b0000_0001 # Set TXD to output, all others to input
    bb.port = 0
    sleep(0.3)
    input("Press Enter to continue...")
    bb.port = 1
    sleep(0.1)
