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

use work.numeric_std.all;

package global is 

  type boolean_vector is array(natural range <>) of boolean;

  -- pragma translate_off
  type shared_boolean is protected
    impure function get return boolean;
    procedure set_true;
    procedure set_false;
    procedure flip;
  end protected shared_boolean;
  -- pragma translate_on
    
  attribute ram_block: boolean;

  subtype word4 is std_ulogic_vector(3 downto 0);   -- half byte
  subtype word8 is std_ulogic_vector(7 downto 0);   -- byte
  subtype word11 is std_ulogic_vector(10 downto 0); -- 11 bits word
  subtype word12 is std_ulogic_vector(11 downto 0); -- 11 bits word
  subtype word14 is std_ulogic_vector(13 downto 0); -- 14 bits word
  subtype word16 is std_ulogic_vector(15 downto 0); -- half word
  subtype word18 is std_ulogic_vector(17 downto 0); -- 18 bits half word
  subtype word24 is std_ulogic_vector(23 downto 0); -- 24 bits word
  subtype word28 is std_ulogic_vector(27 downto 0); -- 28 bits word
  subtype word32 is std_ulogic_vector(31 downto 0); -- word
  subtype word54 is std_ulogic_vector(53 downto 0); -- 54 bits word
  subtype word64 is std_ulogic_vector(63 downto 0); -- double word
  subtype word128 is std_ulogic_vector(127 downto 0); -- quad word

  type word4_vector is array(natural range <>) of word4;
  type word8_vector is array(natural range <>) of word8;
  type word11_vector is array(natural range <>) of word11;
  type word12_vector is array(natural range <>) of word12;
  type word14_vector is array(natural range <>) of word14;
  type word16_vector is array(natural range <>) of word16;
  type word18_vector is array(natural range <>) of word18;
  type word24_vector is array(natural range <>) of word24;
  type word28_vector is array(natural range <>) of word28;
  type word32_vector is array(natural range <>) of word32;
  type word54_vector is array(natural range <>) of word54;
  type word64_vector is array(natural range <>) of word64;
  type word128_vector is array(natural range <>) of word128;

  attribute logic_block: boolean;

end package global;

package body global is

  -- pragma translate_off
  type shared_boolean is protected body
    variable b: boolean := false;
    impure function get return boolean is
    begin
      return b;
    end function get;
    procedure set_true is
    begin
      b := true;
    end procedure set_true;
    procedure set_false is
    begin
      b := false;
    end procedure set_false;
    procedure flip is
    begin
      b := not b;
    end procedure flip;
  end protected body shared_boolean;
  -- pragma translate_on

end package body global;
