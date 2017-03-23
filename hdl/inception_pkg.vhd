library ieee;
use ieee.std_logic_1164.all;

package inception_pkg is

  -- JTAG TAP STATES
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
  constant NSTEPS            : natural := 4;

end package inception_pkg;
