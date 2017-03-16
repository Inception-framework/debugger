library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity tristate is
  port(
       --aclk:       in std_logic;  -- Clock
      --aresetn:    in std_logic;  -- Synchronous, active low, reset

      -- iobuffer
      oe:    in    std_logic;
      dio:   inout std_logic;
      di:    in    std_logic;
      dout:  out   std_logic

    );
end entity tristate;

architecture arch of tristate is
  signal oe_n: std_logic;
begin
  oe_n <= not oe;
  IOBUF_Inst : IOBUF
      port map (
         O     => dout,
         IO    => dio,
         I     => di,
         T     => oe_n);
end architecture arch;
