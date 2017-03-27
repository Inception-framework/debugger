#! /usr/bin/python3.5
################################################################################
#    @Author: Corteggiani Nassim <Corteggiani>                                 #
#    @Email:  nassim.corteggiani@maximintegrated.com                           #
#    @Filename: verify.py                                                #
#    @Last modified by:   Corteggiani                                          #
#    @Last modified time: 21-Mar-2017                                          #
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
from itertools import combinations
import itertools
import subprocess
import os
import time
import binascii

#TODO : the path should be passed as command-line argument !
PATH = "/home/enoname/Tools/altera/13.1/modelsim_ase/linux"

def set_inputs(input):

	f  = open(PATH+"/../bin/jtag_open_cores_test/input.txt", "w")

	input = format(intput, 'x')

	f.write(input+'\n')

	f.close()

def read_outputs():

	# f  = open(PATH+"/../bin/jtag_open_cores_test/output.txt", "r")
	f  = open("io/output.txt", "r")

	lines = f.readlines()

	f.close()

	return lines

def verify(State_start, outputs):
	fsm = jtag_fsm(State_start)

	tms = -1;
	tdi = -1;
	i = 0;

	for line in outputs:
		for c in line:

			if c == '0':
				if i==0 or i%3==0 :
					tms = 0
				else:
					tdi = 0
			if c == '1':
				if i==0 or i%3==0 :
					tms = 1
				else:
					tdi = 1
			if c == 'U':
				if i==0 or i%3==0 :
					tms = -1
				else:
					tdi = -1
			i = i + 1

		print("TMS :"+str(tms)+" TDI :"+str(tdi))

		fsm.run(tms, tdi)

	print("SHIFT DATA REGISTER          : "+"{0:b}".format(fsm.shift_ir))
	print("SHIFT INTRUCTION REGISTER    : "+"{0:b}".format(fsm.shift_dr))

	return fsm

def start_simu():

	err = None
	out = None
	pid = -1

	print("[Simulator]")
	print("	starting...")

	with open(os.devnull, "w") as fnull:
		pipe = subprocess.Popen([PATH+"/vsim", "-c", "-do", "cd "+PATH+"/../bin/jtag_open_cores_test ; do sim.do; quit"], stdout=out, stderr=err)
	print("	simulation in progress...")
	time.sleep(1)

	if err != None :
		print("[ERROR] Unable to run ModelSim : \n\n"+err)
		exit(-1)

	print("	simulation successfully done...")
	print("	closing simulator...")

class jtag_fsm:

	def __init__(self, checkpoint) :
		self.TEST_LOGIC_RESET 	= 0
		self.RUN_TEST_IDLE 		= 1
		self.SELECT_DR_SCAN 	= 2
		self.CAPTURE_DR 		= 3
		self.SHIFT_DR 			= 4
		self.EXIT1_DR			= 5
		self.PAUSE_DR			= 6
		self.EXIT2_DR			= 7
		self.UPDATE_DR			= 8
		self.SELECT_IR_SCAN		= 9
		self.CAPTURE_IR			= 10
		self.SHIFT_IR			= 11
		self.EXIT1_IR			= 12
		self.PAUSE_IR			= 13
		self.EXIT2_IR			= 14
		self.UPDATE_IR			= 15

		self.shift_dr = 0
		self.shift_ir = 0

		self.shift_dr_counter = 0
		self.shift_ir_counter = 0

		self.checkpoint = checkpoint
		self.checkpoint_done = False

		#JTAG Transitions Table
		self.fsm = [
			{'TEST_LOGIC_RESET': {'0':	self.RUN_TEST_IDLE,	'1':	self.TEST_LOGIC_RESET}},

			{'RUN_TEST_IDLE'   : {'0':	self.RUN_TEST_IDLE,	'1':	self.SELECT_DR_SCAN}},

			{'SELECT_DR_SCAN'  : {'0':	self.CAPTURE_DR,	'1':	self.SELECT_IR_SCAN}},
			{'CAPTURE_DR'      : {'0':	self.SHIFT_DR,		'1':	self.EXIT1_DR}},
			{'SHIFT_DR'        : {'0':	self.SHIFT_DR,		'1':	self.EXIT1_DR}},
			{'EXIT1_DR'        : {'0':	self.PAUSE_DR,		'1':	self.UPDATE_DR}},
			{'PAUSE_DR'        : {'0':	self.PAUSE_DR,		'1':	self.EXIT2_DR}},
			{'EXIT2_DR'        : {'0':	self.SHIFT_DR,		'1':	self.UPDATE_DR}},
			{'UPDATE_DR'        : {'0':	self.RUN_TEST_IDLE,	'1':	self.SELECT_DR_SCAN}},

			{'SELECT_IR_SCAN'  : {'0':	self.CAPTURE_IR,	'1':	self.TEST_LOGIC_RESET}},

			{'CAPTURE_IR'      : {'0':	self.SHIFT_IR,		'1':	self.EXIT1_IR}},
			{'SHIFT_IR'        : {'0':	self.SHIFT_IR,		'1':	self.EXIT1_IR}},

			{'EXIT1_IR'        : {'0':	self.PAUSE_IR,		'1':	self.UPDATE_IR}},
			{'PAUSE_IR'        : {'0':	self.PAUSE_IR,		'1':	self.EXIT2_IR}},
			{'EXIT2_IR'        : {'0':	self.SHIFT_IR,		'1':	self.UPDATE_IR}},
			{'UPDATE_IR'        : {'0':	self.RUN_TEST_IDLE,	'1':	self.SELECT_DR_SCAN}}
		]

		self.initial_state = self.TEST_LOGIC_RESET
		self.current_state = -1

	def run(self, tms, tdi):
		if( self.current_state == -1 ):
				self.current_state = self.initial_state

		if self.checkpoint == self.current_state:
			self.checkpoint_done = True

		if self.current_state == self.SHIFT_IR:
			self.shift_ir += (tdi << self.shift_ir_counter)
			self.shift_ir_counter += 1

		if self.current_state == self.SHIFT_DR:
			self.shift_dr += (tdi << self.shift_dr_counter)
			self.shift_dr_counter += 1

		# print(self.fsm[self.current_state])
		key, value = next(iter(self.fsm[self.current_state].items()))
		print("Current state : "+key)

		if tms == 0:
			self.current_state = value['0']
		elif tms == 1:
			self.current_state = value['1']
		else:
			print("unknown transition ...")

		if self.current_state == self.UPDATE_DR:
			print("SHIFT DATA REGISTER          : "+"{0:b}".format(self.shift_dr))
			self.shift_dr_counter = 0
			self.shift_dr = 0

		if self.current_state == self.UPDATE_IR:
			print("SHIFT INTRUCTION REGISTER    : "+"{0:b}".format(self.shift_ir))
			self.shift_ir_counter = 0
			self.shift_ir = 0

if __name__ == "__main__":
	print("\************************************")
	print("*  Internal Jtag Command Generator  *")
	print("\************************************/")

	start_states_dict = {
		'SHIFT_DR': 4,
		'SHIFT_IR': 0xB,
	}

	end_states_dict = {
		'TEST_LOGIC_RESET': 0,
		'RUN_TEST_IDLE': 1,
		'SELECT_DR': 2,
		'CAPTURE_DR': 3,
		# 'SHIFT_DR': 4,
		'EXIT1_DR': 5,
		'PAUSE_DR': 6,
		'EXIT2_DR': 7,
		'UPDATE_DR': 8,
		'SELECT_IR': 9,
		'CAPTURE_IR': 0xA,
		# 'SHIFT_IR': 0xB,
		'EXIT1_IR': 0xC,
		'PAUSE_IR': 0xD,
		'EXIT2_IR': 0xE,
		'UPDATE_IR': 0xF,
	}

	line = -1

	# combi=[]
	# for x in combinations(items,2):
	# 	dic={z:items[z] for z in x}
	# 	combi.append(dic)
	# print(combi)

	# for item in combi:
	combi = itertools.product(start_states_dict, end_states_dict)

	for item in combi:

		print(item)

		State_start_name = item[0]
		State_start = start_states_dict[State_start_name]

		State_end_name = item[1]
		State_end = end_states_dict[State_end_name]
		Shift_register = 0

		if(State_end==4 or State_end == 0xB):
			Shift_count = random.randint(1, 35)
		else:
			Shift_count = 0

		line = line + 1

		intput = 0
		intput = ((State_start & 0xF) << 44)
		intput = intput | ((State_end & 0xF) << 40)
		intput = intput | ((Shift_count & 0xFF) << 32)

		if(State_end==4 or State_end == 0xB):
			intput = intput | (0xABABABAB >> (32-Shift_count) )
			Shift_register = (0xABABABAB >> (32-Shift_count) )


		print("-------------------")
		print("Start State    : "+State_start_name)
		print("End State      : "+State_end_name)
		print("Shift Count    : "+str(Shift_count))
		print("Line           : "+str(line))
		print("Output         : "+hex(intput))
		print("-------------------")

		# set_inputs(intput)

		# start_simu()

		outputs = read_outputs()

		fsm = verify(State_start, outputs)
		error = False

		# if fsm.current_state != State_end:
		# 		print("[ERROR]\n\tFinal state differs from Oracle")
		# 		print("\n\tExpected : "+str(State_end_name))
		# 		key, value = fsm.fsm[fsm.current_state].popitem()
		# 		print("\n\tResult   : "+key)
		# 		error = True
		#
		# if Shift_count > 0 :
		# 	if fsm.shift_ir != Shift_register:
		# 		if fsm.shift_dr != Shift_register:
		# 			print("[ERROR]\n\tShift register value differs from Oracle")
		# 			error = True
		#
		# if error == True:
		# 	exit(0)

		key, value = fsm.fsm[fsm.current_state].popitem()
		print("[Test Done]\n\t Expected "+key+" got "+State_end_name)
		exit(0)
