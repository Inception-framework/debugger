--
-- Copyright (C) Telecom ParisTech
--
-- This file must be used under the terms of the CeCILL.
-- This source file is licensed as described in the file COPYING, which
-- you should have received as part of this distribution.  The terms
-- are also available at
-- http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is

  -- the log2_up function returns the log base 2 of its parameter. the rounding
  -- is toward infinity (log2_up(3) = log2_up(4) = 2). this function is synthesizable by
  -- precision RTL when the parameter is a static constant.
  function log2_up(v: positive) return natural;

  -- returns the or of all bits of the input vector
  function or_reduce(v: std_ulogic_vector) return std_ulogic;

end package utils;

package body utils is

  function log2_up(v: positive) return natural is
    variable res: natural;
  begin
    if v = 1 then return 0;
    else return 1 + log2_up((v + 1) / 2);
    end if;
  end function log2_up;

  function or_reduce(v: std_ulogic_vector) return std_ulogic is
    variable tmp: std_ulogic_vector(v'length - 1 downto 0) := v;
  begin
    if tmp'length = 0 then
      return '0';
    elsif tmp'length = 1 then
      return tmp(0);
    else
      return or_reduce(tmp(tmp'length - 1 downto tmp'length / 2)) or
             or_reduce(tmp(tmp'length / 2 - 1 downto 0));
    end if;
  end function or_reduce;

end package body utils;
