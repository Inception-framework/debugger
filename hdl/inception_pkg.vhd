--Copyright 2018 EURECOM
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.

-- See the README.md file for a detailed description of the Inception debugger

library ieee;
use ieee.std_logic_1164.all;

package inception_pkg is

  ----------------
  -- PARAMETERS --
  ----------------
  constant SYN_DEBUG         : boolean := true; -- enable led/sw etc. hardware for debug
  constant SIM_SYN_N         : boolean := false; --false; -- 1 simulation 0 synthesizable

  ---------------------
  -- JTAG TAP STATES --
  ---------------------
  constant TEST_LOGIC_RESET  : std_logic_vector(3 downto 0) := x"0";
  constant RUN_TEST_IDLE     : std_logic_vector(3 downto 0) := x"1";
  constant SELECT_DR	     : std_logic_vector(3 downto 0) := x"2";
  constant CAPTURE_DR	     : std_logic_vector(3 downto 0) := x"3";
  constant SHIFT_DR	     : std_logic_vector(3 downto 0) := x"4";
  constant EXIT1_DR	     : std_logic_vector(3 downto 0) := x"5";
  constant PAUSE_DR	     : std_logic_vector(3 downto 0) := x"6";
  constant EXIT2_DR	     : std_logic_vector(3 downto 0) := x"7";
  constant UPDATE_DR	     : std_logic_vector(3 downto 0) := x"8";
  constant SELECT_IR	     : std_logic_vector(3 downto 0) := x"9";
  constant CAPTURE_IR	     : std_logic_vector(3 downto 0) := x"A";
  constant SHIFT_IR	     : std_logic_vector(3 downto 0) := x"B";
  constant EXIT1_IR	     : std_logic_vector(3 downto 0) := x"C";
  constant PAUSE_IR	     : std_logic_vector(3 downto 0) := x"D";
  constant EXIT2_IR	     : std_logic_vector(3 downto 0) := x"E";
  constant UPDATE_IR	     : std_logic_vector(3 downto 0) := x"F";

  -- NUMEBER OF MIDDLE LEVEL JTAG COMMANDS TO PERFORM A HIGH LEVEL OP
  constant NSTEPS_WR            : natural := 3;
  constant NSTEPS_RD            : natural := 5;
  constant NSTEPS_RST           : natural := 6;

  -- ADDRESSES
  constant IRQ_ID_ADDR_DEFAULT_LPC1850      : std_logic_vector(31 downto 0) := x"10002000";
  constant IRQ_ID_ADDR_DEFAULT_STM32L152RE  : std_logic_vector(31 downto 0) := x"20002000";
end package inception_pkg;
