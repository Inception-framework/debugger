#! /usr/bin/python3.5
################################################################################
#    @Author: Corteggiani Nassim <Corteggiani>                                 #
#    @Email:  nassim.corteggiani@maximintegrated.com                           #
#    @Filename: hl_inputs.py                                                   #
#    @Last modified by:   Corteggiani                                          #
#    @Last modified time: 23-Mar-2017                                          #
#    @License: GPLv3                                                           #
#                                                                              #
#    Copyright (C) 2017 Maxim Integrated Products, Inc., All Rights Reserved.  #
#    Copyright (C) 2017 Corteggiani Nassim <Corteggiani>                       #
#                                                                              #
#                                                                              #
#    This program is free software: you can redistribute it and/or modify      #
#    it under the terms of the GNU General Public License as published by      #
#    the Free Software Foundation, either version 3 of the License, or         #
#    (at your option) any later version.                                       #
#    This program is distributed in the hope that it will be useful,           #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of            #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
#    GNU General Public License for more details.                              #
#    You should have received a copy of the GNU General Public License         #
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.     #
#                                                                              #
#                                                                              #
################################################################################

import random
import binascii
import os
import subprocess
import time
from collections import OrderedDict
import collections

#TODO : the path should be passed as command-line argument !
PATH = "/home/enoname/Tools/altera/13.1/modelsim_ase/linux"
PATH2 = "/home/noname/Projects/usb3-low-latency-debug/jtag/superspeed-jtag/Debug"

def start_inception():

        pipe = -1

        print("[Inception]")
        print(" starting...")

        # with open(os.devnull, "w") as fnull:
        pipe = subprocess.Popen([PATH2+"/inception", "--debug2"])
        print(" Inception communication in progress...")
        time.sleep(3)

        print(" Inception communication successfully done...")
        print(" closing inception...")
        pipe.kill()

def start_simu():

        err = None
        out = None
        pid = -1

        print("[Simulator]")
        print(" starting...")

        pipe = subprocess.Popen([PATH+"/vsim", "-c", "-do", "cd "+PATH+"/../bin/inception/build/ms ; do ../../scripts/sim.do; quit"])
        print(" simulation in progress...")
        time.sleep(10)

        print(" simulation successfully done...")
        print(" closing simulator...")
        pipe.kill()

def set_inputs(input):

        f  = open(PATH+"/../bin/inception/io/input.txt", "w")

        if isinstance(input, list):
            for line in input:
                f.write(str(line)+'\n')
        else:
            f.write(input+'\n')

        f.close()

# def move_outputs():
#
#         source  = PATH+"/../bin/inception/io/output.txt"
#         dest    = PATH2+"/input.txt"
#
#         pipe = subprocess.Popen(["mv", source, dest])
#         pipe.kill()

if __name__== "__main__":

    HL_COMMANDS = ([('RESET', 0x30000000), ('READ', 0x24000001), ('WRITE', 0x14000001)])

    # {
    #     "RESET" : 0x30000000,
    #     "READ"  : 0x24000001,
    #     "WRITE" : 0x14000001,
    # }

    commands = []

    HL_COMMANDS = collections.OrderedDict(HL_COMMANDS)

    print(HL_COMMANDS)

    for item in HL_COMMANDS:

        print("[Test]\n\ttesting command "+item)

        data_rw = None
        commands.append("{0:0{1}x}".format(HL_COMMANDS[item], 8))
        address = random.randint(0x10000000, 0x20000000)

        print("\tCommand : "+format(HL_COMMANDS[item], 'x'))
        print("\tAddress : "+"{0:0{1}x}".format(address, 8))

        if item == "WRITE" :
            #Data to be write if needed
            data_rw = random.randint(1, 32)
            commands.append("{0:0{1}x}".format(address, 8))
            commands.append("{0:0{1}x}".format(data_rw, 8))
            print("\tData    : "+"{0:0{1}x}".format(data_rw, 8))

        elif item == "READ" :
            commands.append("{0:0{1}x}".format(address, 8))

        elif item == "RESET" :
            commands.append("{0:0{1}x}".format(address, 8))

    set_inputs(commands)

    start_simu()

    print("[Waiting] ....")
    time.sleep(3)

    start_inception()
