#!/usr/bin/python
# Keyboard handling is based on
#   https://www.seasip.info/Unix/Joyce/pcwkbd.html and
#   https://hackaday.io/project/27549-the-pcw-project/log/70757-keyboard-timings

import tkinter as tk
from tkinter import ttk
import cv2
from PIL import Image, ImageTk
from pylibftdi import BitBangDevice
import pylibftdi
import argparse
from pathlib import Path
import os

video_capture_folder = Path("/dev/v4l/by-id")
video_capture_device = str(video_capture_folder / "usb-MACROSIL_AV_TO_USB2.0-video-index0")
ftdi_device = "Old JTAG"

###############################################################################
# FTDI emulation of PCW keyboard protocol
###############################################################################
BITMODE_MPSSE = 0x02

class PcwKeyboardProtocol(object):

    MPSSE_WRITE_NEG        = 0x01 # Write TDI/DO on negative TCK/SK edge
    MPSSE_BITMODE          = 0x02 # Write bits, not bytes
    MPSSE_READ_NEG         = 0x04 # Sample TDO/DI on negative TCK/SK edge
    MPSSE_LSB              = 0x08 # LSB first
    MPSSE_DO_WRITE         = 0x10 # Write TDI/DO
    MPSSE_DO_READ          = 0x20 # Read TDO/DI
    MPSSE_WRITE_TMS        = 0x40 # Write TMS/CS
    SET_BITS_LOW           = 0x80
    SET_BITS_HIGH          = 0x82
    GET_BITS_LOW           = 0x81
    GET_BITS_HIGH          = 0x83
    LOOPBACK_START         = 0x84
    LOOPBACK_END           = 0x85
    TCK_DIVISOR            = 0x86
    DIS_DIV_5              = 0x8a
    EN_DIV_5               = 0x8b
    EN_3_PHASE             = 0x8c
    DIS_3_PHASE            = 0x8d
    CLK_BITS               = 0x8e
    CLK_BYTES              = 0x8f
    CLK_WAIT_HIGH          = 0x94
    CLK_WAIT_LOW           = 0x95
    EN_ADAPTIVE            = 0x96
    DIS_ADAPTIVE           = 0x97
    CLK_BYTES_OR_HIGH      = 0x9c
    CLK_BYTES_OR_LOW       = 0x9d
    DRIVE_OPEN_COLLECTOR   = 0x9e
    SEND_IMMEDIATE         = 0x87
    WAIT_ON_HIGH           = 0x88
    WAIT_ON_LOW            = 0x89
    READ_SHORT             = 0x90
    READ_EXTENDED          = 0x91
    WRITE_SHORT            = 0x92
    WRITE_EXTENDED         = 0x93

    def __init__(self, bb: BitBangDevice):
        self.bb = bb
        self.last_bit = 0

    def set_clock_rate(self, hz: int):
        div = int((12000000 / (hz * 2)) - 1)
        assert self.bb.write(bytes((self.TCK_DIVISOR, div%256, div//256))) == 3


    # In both of these cases, CLK is forced low
    def set_data_high(self):
        assert self.bb.write(bytes((self.SET_BITS_LOW, 0x02, 0x03))) == 3
        self.last_bit = 1

    def set_data_low(self):
        assert self.bb.write(bytes((self.SET_BITS_LOW, 0x00, 0x03))) == 3
        self.last_bit = 0

    def send_byte_start(self):
        self.set_data_low()
        self.set_data_high()
        self.set_data_low()
        self.set_data_high()
        self.set_data_low()

    def send_bit(self, bit):
        assert self.bb.write(bytes((self.SET_BITS_LOW, 0x01 | ((self.last_bit & 1) << 1), 0x03))) == 3
        assert self.bb.write(bytes((self.SET_BITS_LOW, 0x01 | ((bit & 1) << 1), 0x03))) == 3
        assert self.bb.write(bytes((self.SET_BITS_LOW, 0x00 | ((bit & 1) << 1), 0x03))) == 3
        self.last_bit = bit & 1

    # It appears that we can't send data on the appropriate edge. Have to bit-bang the damn thing...
    def send_bits(self, num_bits, byte):
        for i in range(num_bits):
            self.send_bit((byte >> 7) & 1)
            byte <<= 1
        self.set_data_low()

    def send_addr(self, addr):
        #assert bb.write(bytes((MPSSE_WRITE_NEG | MPSSE_DO_WRITE | MPSSE_BITMODE, 3, (addr << 4) & 0xff))) == 3
        self.send_bits(4,addr << 4)

    def send_data(self, data):
        #assert bb.write(bytes((MPSSE_WRITE_NEG | MPSSE_DO_WRITE | MPSSE_BITMODE, 7, data))) == 3
        self.send_bits(8,data)

    def send_byte(self, addr, data):
        self.send_byte_start()
        self.send_addr(addr)
        self.send_data(data)
        self.set_data_low()

class PcwKeyboard(PcwKeyboardProtocol):
    def __init__(self, bb: BitBangDevice):
        super().__init__(bb)
        self.matrix = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        self.matrix_dirty = [False, False, False, False, False, False, False, False, False, False, False, False, False, False, False, False, ]
        self.key_matrix = {
            #49:  # grave (`)
            10:  (0x08, 0), # 1
            11:  (0x08, 1), # 2
            12:  (0x07, 1), # 3
            13:  (0x07, 0), # 4
            14:  (0x06, 1), # 5
            15:  (0x06, 0), # 6
            16:  (0x05, 1), # 7
            17:  (0x05, 0), # 8
            18:  (0x04, 1), # 9
            19:  (0x04, 0), # 0
            20:  (0x03, 1), # minus
            21:  (0x03, 0), # equal
            22:  (0x09, 7), # BackSpace - mapped to '<-DEL'
            #51:  # backslash
            23:  (0x08, 4), # Tab
            35:  (0x02, 1), # bracketright
            34:  (0x03, 2), # bracketleft
            36:  (0x02, 2), # Return
            66:  (0x08, 6), # Caps_Lock
            #48:  # apostrophe
            24:  (0x08, 3), # q
            25:  (0x07, 3), # w
            33:  (0x03, 3), # p
            26:  (0x07, 2), # e
            32:  (0x04, 2), # o
            27:  (0x06, 2), # r
            31:  (0x04, 3), # i
            28:  (0x06, 3), # t
            30:  (0x05, 2), # u
            29:  (0x05, 3), # y
            38:  (0x08, 5), # A
            47:  (0x03, 5), # semicolon
            39:  (0x07, 4), # S
            46:  (0x04, 4), # L
            40:  (0x07, 5), # D
            45:  (0x04, 5), # K
            41:  (0x06, 5), # F
            44:  (0x05, 5), # J
            42:  (0x06, 4), # G
            43:  (0x05, 4), # H
            50:  (0x02, 5), # Shift_L
            52:  (0x08, 7), # z
            53:  (0x07, 7), # x
            54:  (0x07, 6), # C
            55:  (0x06, 7), # V
            56:  (0x06, 6), # B
            57:  (0x05, 6), # N
            58:  (0x04, 6), # M
            59:  (0x04, 7), # comma
            60:  (0x03, 7), # period
            61:  (0x03, 6), # slash
            62:  (0x02, 5), # Shift_R
            105: (0x0a, 1), # Control_R - mapped to 'extra'
            #113: # Left
            108: (0x0a, 7), # Alt_R
            #134: # Super_R
            #135: # Menu
            64:  (0x0a, 7), # Alt_L
            37:  (0x0a, 1), # Control_L - mapped to 'extra'
            65:  (0x05, 7), # space
            9:   (0x08, 2), # Escape - mapped to 'stop'
            67:  (0x00, 2), # F1 - mapped to 'F1/F2'
            68:  (0x00, 0), # F2 - mapped to 'F3/F4'
            69:  (0x0a, 0), # F3 - mapped to 'F5/F6'
            70:  (0x0a, 4), # F4 - mapped to 'F7/F8'
            71:  (0x0a, 2), # F5 - mapped to 'can(cel)'
            72:  (0x01, 2), # F6 - mapped to 'cut'
            73:  (0x01, 3), # F7 - mapped to 'copy'
            74:  (0x00, 3), # F8 - mapped to 'paste'
            75:  (0x02, 7), # F9 - mapped to '[+]'
            76:  (0x0a, 3), # F10 - mapped to '[-]'
            95:  (0x01, 1), # F11 - mapped to 'ptr'
            96:  (0x01, 0), # F12 - mapped to 'exit'
            #78:  # Scroll_Lock
            #118: # Insert
            119: (0x02, 0), # Delete - mapped to 'DEL->'

            #110: # Home
            #112: # Prior
            #115: # End
            #117: # Next
            #111: # Up
            #116: # Down
            #114: # Right
            #113: # Left
            #77:  # Num_Lock
            #106: # KP_Divide
            #63:  # KP_Multiply
            #82:  # KP_Subtract
            #79:  # KP_Home
            #80:  # KP_Up
            #81:  # KP_Prior
            #83:  # KP_Left
            #84:  # KP_Begin
            #85:  # KP_Right
            #87:  # KP_End
            #88:  # KP_Down
            #89:  # KP_Next
            #90:  # KP_Insert
            #91:  # KP_Delete
            #104: # KP_Enter
            #86:  # KP_Add
        }

    def force_send_matrix(self):
        for i in range(len(self.matrix_dirty)): self.matrix_dirty[i] = True
        self.send_matrix()

    def send_matrix(self):
        if any(self.matrix_dirty):
            #print("---")
            self.matrix[0xf] &= 0x7f # Make sure that busy flag is never set in the matrix
            self.send_byte(0xf, self.matrix[0xf] | 0x80) # Set busy flag
            for b in range(16):
                if self.matrix_dirty[b] or b == 15:
                    self.send_byte(b, self.matrix[b])
                self.matrix_dirty[b] = False
            # Toggle the ticker bit
            self.matrix[0xf] ^= 0x40

    def send_keydown(self, keycode):
        try:
            matrix_ptr = self.key_matrix[keycode]
            self.matrix[matrix_ptr[0]] |= 1 << matrix_ptr[1]
            self.matrix_dirty[matrix_ptr[0]] = True
            self.send_matrix()
        except KeyError:
            pass

    def send_keyup(self, keycode):
        try:
            matrix_ptr = self.key_matrix[keycode]
            self.matrix[matrix_ptr[0]] &= 0xff ^ (1 << matrix_ptr[1])
            self.matrix_dirty[matrix_ptr[0]] = True
            self.send_matrix()
        except KeyError:
            pass

    def init(self):
        #self.set_data_low()
        #self.set_clock_rate(30_000) # 30kHz seems to be the clock rate (though in the HW it's not 50% duty cycle)
        self.force_send_matrix()


def main_window(capture_card, ftdi_device):
    kbd_interface: PcwKeyboard = None

    def key_press(event):
        if kbd_interface is not None:
            kbd_interface.send_keydown(event.keycode)
        #print(f"Pressed {event.char}, {event.keysym}, {event.keycode}")

    def key_release(event):
        if kbd_interface is not None:
            kbd_interface.send_keyup(event.keycode)
        #print(f"Released {event.char}, {event.keysym}, {event.keycode}")

    def capture_video():
        ret, frame = cap.read()
        if ret:
            cv2image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
            img = Image.fromarray(cv2image)
            imgtk = ImageTk.PhotoImage(image=img)
            lmain.imgtk = imgtk
            lmain.configure(image=imgtk)
            lmain.after(10, capture_video)

    with BitBangDevice(device_id=ftdi_device, interface_select=pylibftdi.INTERFACE_A, bitbang_mode=BITMODE_MPSSE) as bb:
        kbd_interface = PcwKeyboard(bb)
        kbd_interface.init()

        # Create a window
        window = tk.Tk()
        window.bind("<KeyPress>", key_press)
        window.bind("<KeyRelease>", key_release)
        window.title("PCW Controller")

        # Create a label to display video frames
        lmain = ttk.Label(window)
        lmain.grid(row=0, column=0, padx=10, pady=10)

        # Initialize video capture
        cap = cv2.VideoCapture(capture_card)
        capture_video()

        # Run the tkinter event loop
        window.mainloop()

parser = argparse.ArgumentParser(
    prog='pcw_ctrl',
    description='Control a PCW8256 remotely through a video capture card and an FTDI-chip based keyboard emulator',
    epilog='Good luck!'
)

parser.add_argument("--list-capture-cards", help="List available video capture devices and exit", action="store_true")
parser.add_argument("--list-ftdi", help="List available FTDI devices and exit", action="store_true")
parser.add_argument("-c", "--capture-card", help="Specify video capture devices and exit", default=video_capture_device)
parser.add_argument("-f", "--ftdi", help="Specify FTDI device to use", default=ftdi_device)

def list_ftdi():
    device_list = pylibftdi.Driver().list_devices()
    for vendor, product, serial in pylibftdi.Driver().list_devices():
        print(f"{product}: from {vendor} with serial {serial}")

def list_capture_cards():
    for path in video_capture_folder.iterdir():
        if path.is_dir():
            continue
        print(path)


args = parser.parse_args()

if args.list_ftdi:
    list_ftdi()
    exit()

if args.list_capture_cards:
    list_capture_cards()
    exit()

main_window(args.capture_card, args.ftdi)