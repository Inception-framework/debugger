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

--pragma translate_off
use std.textio.all;
--pragma translate_on

use work.numeric_std.all;
use work.global.all;

package utils is

  -- Decode a n-bits word as a 2^n bits one-hot encoding: the leftmost bit of
  -- the result is set if a = (others => '0')...
  function decode(a: unsigned) return unsigned;
  function decode(a: std_ulogic_vector) return std_ulogic_vector;
  function decode(a: std_ulogic) return std_ulogic_vector;

  -- left shift (zeroes enter on the right)
  function shift_left(a: std_ulogic_vector; n: natural) return std_ulogic_vector;

  -- unsigned right shift (zeroes enter on the left)
  function shift_right(a: std_ulogic_vector; n: natural) return std_ulogic_vector;

  -- left rotate
  function rotate_left(a: std_ulogic_vector; n: natural) return std_ulogic_vector;

  -- right rotate
  function rotate_right(a: std_ulogic_vector; n: natural) return std_ulogic_vector;

	function min(a: integer; b: integer) return integer;

  -- the log2_down function returns the log base 2 of its parameter. the rounding
  -- is toward zero (log2_down(2) = log2_down(3) = 1). this function is synthesizable by
  -- precision RTL when the parameter is a static constant.
  function log2_down(v: positive) return natural;

  -- the log2_up function returns the log base 2 of its parameter. the rounding
  -- is toward infinity (log2_up(3) = log2_up(4) = 2). this function is synthesizable by
  -- precision RTL when the parameter is a static constant.
  function log2_up(v: positive) return natural;

  -- converts a std_ulogic to integer 0 or 1
  function to_i01(v: std_ulogic) return natural;

  -- returns the and of all bits of the input vector
  function and_reduce(v: std_ulogic_vector) return std_ulogic;
--  function and_reduce(v: std_logic_vector) return std_ulogic;
  function and_reduce(v: unsigned) return std_ulogic;
  function and_reduce(v: signed) return std_ulogic;
--function and_reduce(v: boolean_vector) return boolean;

  -- returns the or of all bits of the input vector
  function or_reduce(v: std_ulogic_vector) return std_ulogic;
--  function or_reduce(v: std_logic_vector) return std_ulogic;
  function or_reduce(v: unsigned) return std_ulogic;
  function or_reduce(v: signed) return std_ulogic;
--function or_reduce(v: boolean_vector) return boolean;

  -- left extends input vector to size bits with zeros
  function zero_pad_left(v: std_ulogic_vector; size: natural) return std_ulogic_vector;
	-- and between a vector and a bit
	function band(l: std_ulogic_vector; r: std_ulogic) return std_ulogic_vector;
	function band(l: std_ulogic; r: std_ulogic_vector) return std_ulogic_vector;
	function band(l: unsigned; r: std_ulogic) return unsigned;
	function band(l: std_ulogic; r: unsigned) return unsigned;
	function band(l: signed; r: std_ulogic) return signed;
	function band(l: std_ulogic; r: signed) return signed;

  function unsigned_resize(v: std_ulogic_vector; n: positive) return std_ulogic_vector;

  function to_stdulogic(b: boolean) return std_ulogic;

  function mask_bytes(v: std_ulogic_vector; b: std_ulogic_vector) return std_ulogic_vector;
  function mask_bytes(o: std_ulogic_vector; n: std_ulogic_vector; b: std_ulogic_vector) return std_ulogic_vector;
  function expand_bits_to_bytes(v: std_ulogic_vector) return std_ulogic_vector;

  -- returns n MSBs of v, indexed n-1 downto 0
  function get_msbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector;
  function get_msbs(v: unsigned; n: natural) return unsigned;
  function get_msbs(v: signed; n: natural) return signed;
  -- returns n LSBs of v, indexed n-1 downto 0
  function get_lsbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector;
  function get_lsbs(v: unsigned; n: natural) return unsigned;
  function get_lsbs(v: signed; n: natural) return signed;
  -- drops the n MSBs of v and returns the remaining LSBs indexed x-1 downto 0
  function drop_msbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector;
  function drop_msbs(v: unsigned; n: natural) return unsigned;
  function drop_msbs(v: signed; n: natural) return signed;
  -- drops the n LSBs of v and returns the remaining MSBs indexed x-1 downto 0
  function drop_lsbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector;
  function drop_lsbs(v: unsigned; n: natural) return unsigned;
  function drop_lsbs(v: signed; n: natural) return signed;

  -- Vector swapping. Recursively swaps v halves, quarters, eigths,... under control of bits of s, starting with MSB of s for the halves swapping. Examples:
  -- vector_swap("00011011", "00") = "00011011"
  -- vector_swap("00011011", "01") = "01001110"
  -- vector_swap("00011011", "10") = "10110001"
  -- vector_swap("00011011", "11") = "11100100"
  function vector_swap(v: std_ulogic_vector; s: std_ulogic_vector) return std_ulogic_vector;

end package utils;

package body utils is

  function decode(a: unsigned) return unsigned is
    constant n: natural := a'length;
    variable tmp: unsigned(n - 1 downto 0) := a;
    variable res: unsigned(2**n - 1 downto 0);
  begin
    if n = 0 then
      res := "1";
    elsif n = 1 then
      if tmp(0) = '0' then
        res := "10";
      else
        res := "01";
      end if;
    else
      res := band((not tmp(n - 1)), decode(tmp(n - 2 downto 0))) & band(tmp(n - 1), decode(tmp(n - 2 downto 0)));
    end if;
    return res;
  end function decode;

  function decode(a: std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(decode(unsigned(a)));
  end function decode;

  function decode(a: std_ulogic) return std_ulogic_vector is
    variable va: std_ulogic_vector(0 downto 0);
  begin
    va(0) := a;
    return decode(va);
  end function decode;

  function shift_left(a: std_ulogic_vector; n: natural) return std_ulogic_vector is
  begin
    return std_ulogic_vector(shift_left(unsigned(a), n));
  end function shift_left;

  function shift_right(a: std_ulogic_vector; n: natural) return std_ulogic_vector is
  begin
    return std_ulogic_vector(shift_right(unsigned(a), n));
  end function shift_right;

  function rotate_left(a: std_ulogic_vector; n: natural) return std_ulogic_vector is
  begin
    return std_ulogic_vector(rotate_left(unsigned(a), n));
  end function rotate_left;

  function rotate_right(a: std_ulogic_vector; n: natural) return std_ulogic_vector is
  begin
    return std_ulogic_vector(rotate_right(unsigned(a), n));
  end function rotate_right;

	function min(a: integer; b: integer) return integer is
	begin
		if a < b then
			return a;
		else
			return b;
		end if;
	end function min;

  function log2_down(v: positive) return natural is
    variable res: natural;
  begin
    if v = 1 then return 0;
    else return 1 + log2_down(v / 2);
    end if;
  end function log2_down;

  function log2_up(v: positive) return natural is
    variable res: natural;
  begin
    if v = 1 then return 0;
    else return 1 + log2_up((v + 1) / 2);
    end if;
  end function log2_up;

  function to_i01(v: std_ulogic) return natural is
    variable res: natural range 0 to 1 := 0;
  begin
    if v = '1' then
      res := 1;
--pragma translate_off
    elsif v /= '0' then
      assert false
        report "to_i01: 'U'|'X'|'W'|'Z'|'-'|'L'|'H' input"
        severity warning;
--pragma translate_on
    end if;
    return res;
  end function to_i01;

  function and_reduce(v: std_ulogic_vector) return std_ulogic is
    variable tmp: std_ulogic_vector(v'length - 1 downto 0) := v;
  begin
    if tmp'length = 0 then
      return '0';
    elsif tmp'length = 1 then
      return tmp(0);
    else
      return and_reduce(tmp(tmp'length - 1 downto tmp'length / 2)) and
             and_reduce(tmp(tmp'length / 2 - 1 downto 0));
    end if;
  end function and_reduce;

--  function and_reduce(v: std_logic_vector) return std_ulogic is
--	begin
--		return and_reduce(std_ulogic_vector(v));
--	end function and_reduce;
--
  function and_reduce(v: unsigned) return std_ulogic is
	begin
		return and_reduce(std_ulogic_vector(v));
	end function and_reduce;

  function and_reduce(v: signed) return std_ulogic is
	begin
		return and_reduce(std_ulogic_vector(v));
	end function and_reduce;

-- function and_reduce(v: boolean_vector) return boolean is
--   variable tmp: boolean_vector(v'length - 1 downto 0) := v;
-- begin
--   if tmp'length = 0 then
--     return false;
--   elsif tmp'length = 1 then
--     return tmp(0);
--   else
--     return and_reduce(tmp(tmp'length - 1 downto tmp'length / 2)) and
--            and_reduce(tmp(tmp'length / 2 - 1 downto 0));
--   end if;
-- end function and_reduce;

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

--  function or_reduce(v: std_logic_vector) return std_ulogic is
--	begin
--		return or_reduce(std_ulogic_vector(v));
--	end function or_reduce;
--
  function or_reduce(v: unsigned) return std_ulogic is
	begin
		return or_reduce(std_ulogic_vector(v));
	end function or_reduce;

  function or_reduce(v: signed) return std_ulogic is
	begin
		return or_reduce(std_ulogic_vector(v));
	end function or_reduce;

-- function or_reduce(v: boolean_vector) return boolean is
--   variable tmp: boolean_vector(v'length - 1 downto 0) := v;
-- begin
--   if tmp'length = 0 then
--     return false;
--   elsif tmp'length = 1 then
--     return tmp(0);
--   else
--     return or_reduce(tmp(tmp'length - 1 downto tmp'length / 2)) or
--            or_reduce(tmp(tmp'length / 2 - 1 downto 0));
--   end if;
-- end function or_reduce;

  function zero_pad_left(v: std_ulogic_vector; size: natural) return std_ulogic_vector is
    variable res: std_ulogic_vector(size - 1 downto 0);
  begin
    assert v'length <= size
      report "zero_pad_left: cannot downsize"
      severity failure;
    res := (others => '0');
    res(v'length - 1 downto 0) := v;
    return res;
  end function zero_pad_left;

	function band(l: std_ulogic_vector; r: std_ulogic)
	  return std_ulogic_vector is
		variable tmp: std_ulogic_vector(0 to l'length - 1) := l;
	begin
    for i in 0 to l'length - 1 loop
			tmp(i) := tmp(i) and r;
		end loop;
		return tmp;
	end function band;

	function band(l: std_ulogic; r: std_ulogic_vector)
	  return std_ulogic_vector is
	begin
		return band(r, l);
	end function band;

  function band(l: unsigned; r: std_ulogic) return unsigned is
  begin
    return unsigned(band(std_ulogic_vector(l), r));
  end function band;

  function band(l: std_ulogic; r: unsigned) return unsigned is
  begin
    return unsigned(band(std_ulogic_vector(r), l));
  end function band;

  function band(l: signed; r: std_ulogic) return signed is
  begin
    return signed(band(std_ulogic_vector(l), r));
  end function band;

  function band(l: std_ulogic; r: signed) return signed is
  begin
    return signed(band(std_ulogic_vector(r), l));
  end function band;

  function unsigned_resize(v: std_ulogic_vector; n: positive) return std_ulogic_vector is
    variable res: std_ulogic_vector(n - 1 downto 0) := (others => '0');
    variable tmp: std_ulogic_vector(v'length - 1 downto 0) := v;
  begin
    if n >= v'length then
      res(v'length - 1 downto 0) := v;
    else
      res := tmp(n - 1 downto 0);
    end if;
    return res;
  end function unsigned_resize;

  function to_stdulogic(b: boolean) return std_ulogic is
    variable res: std_ulogic := '0';
  begin
    if b then
      res := '1';
    end if;
    return res;
  end function to_stdulogic;

  function mask_bytes(v: std_ulogic_vector; b: std_ulogic_vector) return std_ulogic_vector is
    constant nv: natural := v'length;
    constant nb: natural := b'length;
    variable vv: std_ulogic_vector(nv - 1 downto 0) := v;
    variable res: std_ulogic_vector(nv - 1 downto 0) := (others => '0');
    variable vb: std_ulogic_vector(nb - 1 downto 0) := b;
  begin
    assert nv = nb * 8
      report "mask_bytes: invalid parameters"
      severity failure;
    for i in 0 to nb - 1 loop
      if vb(i) = '1' then
        res(8 * i + 7 downto 8 * i) := vv(8 * i + 7 downto 8 * i);
      end if;
    end loop;
    return res;
  end function mask_bytes;

  function mask_bytes(o: std_ulogic_vector; n: std_ulogic_vector; b: std_ulogic_vector) return std_ulogic_vector is
  begin
    return mask_bytes(o, not b) or mask_bytes(n, b);
  end function mask_bytes;

  function expand_bits_to_bytes(v: std_ulogic_vector) return std_ulogic_vector is
    constant nb: natural := v'length;
    variable vv: std_ulogic_vector(nb - 1 downto 0) := v;
    variable res: std_ulogic_vector(8 * nb - 1 downto 0) := (others => '0');
  begin
    for i in 0 to nb - 1 loop
      if vv(i) = '1' then
        res(8 * i + 7 downto 8 * i) := X"FF";
      end if;
    end loop;
    return res;
  end function expand_bits_to_bytes;

  function get_msbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector is
    constant vn: natural := v'length;
    variable tmp: std_ulogic_vector(vn - 1 downto 0) := v;
    variable res: std_ulogic_vector(n - 1 downto 0);
  begin
    assert n <= vn report "get_msbs: invalid parameters" severity failure;
    res := tmp(vn - 1 downto vn - n);
    return res;
  end function get_msbs;

  function get_msbs(v: unsigned; n: natural) return unsigned is
  begin
    return unsigned(get_msbs(std_ulogic_vector(v), n));
  end function get_msbs;

  function get_msbs(v: signed; n: natural) return signed is
  begin
    return signed(get_msbs(std_ulogic_vector(v), n));
  end function get_msbs;

  function get_lsbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector is
    constant vn: natural := v'length;
    variable tmp: std_ulogic_vector(vn - 1 downto 0) := v;
    variable res: std_ulogic_vector(n - 1 downto 0);
  begin
    assert n <= vn report "get_msbs: invalid parameters" severity failure;
    res := tmp(n - 1 downto 0);
    return res;
  end function get_lsbs;

  function get_lsbs(v: unsigned; n: natural) return unsigned is
  begin
    return unsigned(get_lsbs(std_ulogic_vector(v), n));
  end function get_lsbs;

  function get_lsbs(v: signed; n: natural) return signed is
  begin
    return signed(get_lsbs(std_ulogic_vector(v), n));
  end function get_lsbs;

  function drop_msbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector is
    constant vn: natural := v'length;
    variable tmp: std_ulogic_vector(vn - 1 downto 0) := v;
    variable res: std_ulogic_vector(vn - n - 1 downto 0);
  begin
    assert n <= vn report "drop_msbs: invalid parameters" severity failure;
    res := tmp(vn - n - 1 downto 0);
    return res;
  end function drop_msbs;

  function drop_msbs(v: unsigned; n: natural) return unsigned is
  begin
    return unsigned(drop_msbs(std_ulogic_vector(v), n));
  end function drop_msbs;

  function drop_msbs(v: signed; n: natural) return signed is
  begin
    return signed(drop_msbs(std_ulogic_vector(v), n));
  end function drop_msbs;

  function drop_lsbs(v: std_ulogic_vector; n: natural) return std_ulogic_vector is
    constant vn: natural := v'length;
    variable tmp: std_ulogic_vector(vn - 1 downto 0) := v;
    variable res: std_ulogic_vector(vn - n - 1 downto 0);
  begin
    assert n <= vn report "drop_lsbs: invalid parameters" severity failure;
    res := tmp(vn - 1 downto n);
    return res;
  end function drop_lsbs;


  function drop_lsbs(v: unsigned; n: natural) return unsigned is
  begin
    return unsigned(drop_lsbs(std_ulogic_vector(v), n));
  end function drop_lsbs;

  function drop_lsbs(v: signed; n: natural) return signed is
  begin
    return signed(drop_lsbs(std_ulogic_vector(v), n));
  end function drop_lsbs;

  function vector_swap(v: std_ulogic_vector; s: std_ulogic_vector) return std_ulogic_vector is
    constant nv: natural := v'length;
    variable vv: std_ulogic_vector(nv - 1 downto 0) := v;
    constant ns: natural := s'length;
    variable vs: std_ulogic_vector(ns - 1 downto 0) := s;
  begin
    -- pragma translate_off
    assert ns >= 1 and (nv / 8 = 2**ns or nv = 2**ns) report "Invalid parameters" severity failure;
    -- pragma translate_on
    if vs(ns - 1) = '1' then
      vv := vv(nv / 2 - 1 downto 0) & vv(nv - 1 downto nv / 2);
    end if;
    if ns /= 1 then
      vv := vector_swap(vv(nv - 1 downto nv / 2), vs(ns - 2 downto 0)) & vector_swap(vv(nv / 2 - 1 downto 0), vs(ns - 2 downto 0));
    end if;
    return vv;
  end function vector_swap;

end package body utils;
