--
-- SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
-- Copyright (C) 2015 - Telecom ParisTech
--
-- This file must be used under the terms of the CeCILL.
-- This source file is licensed as described in the file COPYING, which
-- you should have received as part of this distribution.  The terms
-- are also available at
-- http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
--

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;

library random_lib;
use random_lib.rnd.all;

use work.global.all;
use work.sim_utils.all;

entity sim_utils_sim is
end entity sim_utils_sim;

architecture sim of sim_utils_sim is
begin
  process
    variable crc: word32;
    variable val: word32_vector(1 to 100);
    variable l: line;
  begin
    for j in 1 to 10 loop
      for i in 1 to 100 loop
        val(i) := std_ulogic_vector_rnd(32);
      end loop;
      crc := crc32_0x104c11db7(val);
      hwrite(l, crc);
      writeline(output, l);
    end loop;
    report "Non-regression test passed, end of simulation.";
    wait;
  end process;
end architecture sim;
