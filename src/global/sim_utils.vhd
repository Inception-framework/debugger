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

use work.numeric_std.all;
use work.global.all;
use work.utils.all;

package sim_utils is

  -- Compare bits and vectors. Don't care values ('-') are ignored.
  function check(a, b: std_ulogic) return boolean;
  function check(a, b: std_ulogic_vector) return boolean;

  procedure crc32_0x104c11db7(crc: inout word32; val: in word32);
  procedure crc32_0x104c11db7(crc: inout word32; val: in word32_vector);
  function crc32_0x104c11db7(val: word32_vector) return word32;

  type natural_vector is array(natural range <>) of natural;

  --* Print percentage progress i/n
  procedure progress(i: positive; n: positive);

  function is_01(v: std_ulogic_vector) return boolean;
  function is_01(v: unsigned) return boolean;
  function is_01(v: signed) return boolean;

  --* Read an unsigned  hexadecimal value from line L. Stop at end of line or first non-hex character. GOOD is an exit status set to false when the first
  --* character is non-hex, the line is empty or on overflow of the VAL output parameter. On errors the L parameter is left unmodified. On success the line
  --* parameter is either empty or points to the first non-hex character.
  procedure hread(l: inout line; val: out bit_vector; good: out boolean);
  procedure hread(l: inout line; val: out std_ulogic_vector; good: out boolean);
  procedure hread(l: inout line; val: out unsigned; good: out boolean);
  procedure hread(l: inout line; val: out signed; good: out boolean);
  procedure hread(l: inout line; val: out natural; good: out boolean);
--  procedure hread(l: inout line; val: out bit_vector);
  procedure hread(l: inout line; val: out std_ulogic_vector);
  procedure hread(l: inout line; val: out unsigned);
  procedure hread(l: inout line; val: out signed);
  procedure hread(l: inout line; val: out natural);
	--* Write in decimal form
	procedure dwrite(l: inout line; val: in bit_vector);
	procedure dwrite(l: inout line; val: in std_ulogic_vector);
	procedure dwrite(l: inout line; val: in unsigned);
	procedure dwrite(l: inout line; val: in signed);
	--* Write in hex form
	procedure hwrite(l: inout line; val: in bit_vector);
	procedure hwrite(l: inout line; val: in std_ulogic_vector);
	procedure hwrite(l: inout line; val: in unsigned);
	procedure hwrite(l: inout line; val: in signed);
  --* Write in binary form
	procedure write(l: inout line; val: in std_ulogic);
	procedure write(l: inout line; val: in std_ulogic_vector);
	procedure write(l: inout line; val: in unsigned);
	procedure write(l: inout line; val: in signed);
  --* Write string
	procedure print(l: inout line; val: in string);
	procedure print(val: in string);

  --* Converts an hexadecimal character ([0-9a-fA-F]) to an integer (0 to 15). Returns -1 if C is not an hexadecimal character.
  function char2hex(c: character) return integer;

  --* Converts a decimal character to integer (0 to 9). Returns -1 if C is not a decimal character.
  function char2dec(c: character) return integer;

  --* Converts a binary character to integer (0 to 1). Returns -1 if C is not a binary character.
  function char2bin(c: character) return integer;

  --* Byte-enabled equality check. EXP and GOT must be 8*N bits long and MASK must be N bits long for some N.
	function masked_check(mask: std_ulogic_vector; exp: std_ulogic_vector; got: std_ulogic_vector) return boolean;

  -- Vector comparison checker. Different lengths do not match. Do not care bits ('-') always match
  function vector_check(a, b: std_ulogic_vector) return boolean;

  --* Conversion from natural to character.
  constant hex2char: string(1 to 16) := "0123456789abcdef";

  --* Conversion from std_ulogic_vector to hex string.
  function vec2hexstr(val: std_ulogic_vector) return string;

  --* Conversion from std_ulogic to character.
	type std2char_type is array(std_ulogic) of character;
  constant std2char: std2char_type := ('U' => 'U', 'X' => 'X', '0' => '0', '1' => '1', 'Z' => 'Z', 'W' => 'W', 'L' => 'L', 'H' => 'H', '-' => '-');

  type shared_natural is protected
    impure function get return natural;
    procedure inc;
  end protected shared_natural;

end package sim_utils;

package body sim_utils is

  function check(a, b: std_ulogic) return boolean is
  begin
    return a = b or a = '-' or b = '-';
  end function check;

  function check(a, b: std_ulogic_vector) return boolean is
    variable va: std_ulogic_vector(a'length - 1 downto 0) := a;
    variable vb: std_ulogic_vector(b'length - 1 downto 0) := b;
  begin
    if a'length /= b'length then
      return false;
    end if;
    for i in 0 to a'length - 1 loop
      if not check(va(i), vb(i)) then
        return false;
      end if;
    end loop;
    return true;
  end function check;

  constant crc32_0x104c11db7_const: word32_vector(0 to 255) := (
    X"00000000", X"04C11DB7", X"09823B6E", X"0D4326D9", X"130476DC", X"17C56B6B", X"1A864DB2", X"1E475005", X"2608EDB8", X"22C9F00F", X"2F8AD6D6", X"2B4BCB61", X"350C9B64", X"31CD86D3", X"3C8EA00A", X"384FBDBD",
    X"4C11DB70", X"48D0C6C7", X"4593E01E", X"4152FDA9", X"5F15ADAC", X"5BD4B01B", X"569796C2", X"52568B75", X"6A1936C8", X"6ED82B7F", X"639B0DA6", X"675A1011", X"791D4014", X"7DDC5DA3", X"709F7B7A", X"745E66CD",
    X"9823B6E0", X"9CE2AB57", X"91A18D8E", X"95609039", X"8B27C03C", X"8FE6DD8B", X"82A5FB52", X"8664E6E5", X"BE2B5B58", X"BAEA46EF", X"B7A96036", X"B3687D81", X"AD2F2D84", X"A9EE3033", X"A4AD16EA", X"A06C0B5D",
    X"D4326D90", X"D0F37027", X"DDB056FE", X"D9714B49", X"C7361B4C", X"C3F706FB", X"CEB42022", X"CA753D95", X"F23A8028", X"F6FB9D9F", X"FBB8BB46", X"FF79A6F1", X"E13EF6F4", X"E5FFEB43", X"E8BCCD9A", X"EC7DD02D",
    X"34867077", X"30476DC0", X"3D044B19", X"39C556AE", X"278206AB", X"23431B1C", X"2E003DC5", X"2AC12072", X"128E9DCF", X"164F8078", X"1B0CA6A1", X"1FCDBB16", X"018AEB13", X"054BF6A4", X"0808D07D", X"0CC9CDCA",
    X"7897AB07", X"7C56B6B0", X"71159069", X"75D48DDE", X"6B93DDDB", X"6F52C06C", X"6211E6B5", X"66D0FB02", X"5E9F46BF", X"5A5E5B08", X"571D7DD1", X"53DC6066", X"4D9B3063", X"495A2DD4", X"44190B0D", X"40D816BA",
    X"ACA5C697", X"A864DB20", X"A527FDF9", X"A1E6E04E", X"BFA1B04B", X"BB60ADFC", X"B6238B25", X"B2E29692", X"8AAD2B2F", X"8E6C3698", X"832F1041", X"87EE0DF6", X"99A95DF3", X"9D684044", X"902B669D", X"94EA7B2A",
    X"E0B41DE7", X"E4750050", X"E9362689", X"EDF73B3E", X"F3B06B3B", X"F771768C", X"FA325055", X"FEF34DE2", X"C6BCF05F", X"C27DEDE8", X"CF3ECB31", X"CBFFD686", X"D5B88683", X"D1799B34", X"DC3ABDED", X"D8FBA05A",
    X"690CE0EE", X"6DCDFD59", X"608EDB80", X"644FC637", X"7A089632", X"7EC98B85", X"738AAD5C", X"774BB0EB", X"4F040D56", X"4BC510E1", X"46863638", X"42472B8F", X"5C007B8A", X"58C1663D", X"558240E4", X"51435D53",
    X"251D3B9E", X"21DC2629", X"2C9F00F0", X"285E1D47", X"36194D42", X"32D850F5", X"3F9B762C", X"3B5A6B9B", X"0315D626", X"07D4CB91", X"0A97ED48", X"0E56F0FF", X"1011A0FA", X"14D0BD4D", X"19939B94", X"1D528623",
    X"F12F560E", X"F5EE4BB9", X"F8AD6D60", X"FC6C70D7", X"E22B20D2", X"E6EA3D65", X"EBA91BBC", X"EF68060B", X"D727BBB6", X"D3E6A601", X"DEA580D8", X"DA649D6F", X"C423CD6A", X"C0E2D0DD", X"CDA1F604", X"C960EBB3",
    X"BD3E8D7E", X"B9FF90C9", X"B4BCB610", X"B07DABA7", X"AE3AFBA2", X"AAFBE615", X"A7B8C0CC", X"A379DD7B", X"9B3660C6", X"9FF77D71", X"92B45BA8", X"9675461F", X"8832161A", X"8CF30BAD", X"81B02D74", X"857130C3",
    X"5D8A9099", X"594B8D2E", X"5408ABF7", X"50C9B640", X"4E8EE645", X"4A4FFBF2", X"470CDD2B", X"43CDC09C", X"7B827D21", X"7F436096", X"7200464F", X"76C15BF8", X"68860BFD", X"6C47164A", X"61043093", X"65C52D24",
    X"119B4BE9", X"155A565E", X"18197087", X"1CD86D30", X"029F3D35", X"065E2082", X"0B1D065B", X"0FDC1BEC", X"3793A651", X"3352BBE6", X"3E119D3F", X"3AD08088", X"2497D08D", X"2056CD3A", X"2D15EBE3", X"29D4F654",
    X"C5A92679", X"C1683BCE", X"CC2B1D17", X"C8EA00A0", X"D6AD50A5", X"D26C4D12", X"DF2F6BCB", X"DBEE767C", X"E3A1CBC1", X"E760D676", X"EA23F0AF", X"EEE2ED18", X"F0A5BD1D", X"F464A0AA", X"F9278673", X"FDE69BC4",
    X"89B8FD09", X"8D79E0BE", X"803AC667", X"84FBDBD0", X"9ABC8BD5", X"9E7D9662", X"933EB0BB", X"97FFAD0C", X"AFB010B1", X"AB710D06", X"A6322BDF", X"A2F33668", X"BCB4666D", X"B8757BDA", X"B5365D03", X"B1F740B4"
    );

  procedure crc32_0x104c11db7(crc: inout word32; val: in word32) is
    variable tmp: word32 := val;
  begin
    for i in 0 to 3 loop
      crc := crc32_0x104c11db7_const(to_integer(unsigned(crc(31 downto 24) xor tmp(31 downto 24)))) xor (crc(23 downto 0) & X"00");
      tmp := tmp(23 downto 0) & X"00";
    end loop;
  end procedure crc32_0x104c11db7;

  procedure crc32_0x104c11db7(crc: inout word32; val: in word32_vector) is
  begin
    for i in val'range loop
      crc32_0x104c11db7(crc, val(i));
    end loop;
  end procedure crc32_0x104c11db7;

  function crc32_0x104c11db7(val: word32_vector) return word32 is
    variable crc: word32 := X"FFFFFFFF";
  begin
    for i in val'range loop
      crc32_0x104c11db7(crc, val(i));
    end loop;
    crc := crc xor X"FFFFFFFF";
    return crc;
  end function crc32_0x104c11db7;

  procedure progress(i: positive; n: positive) is
    variable l: line;
  begin
    write(l, i);
    print(l, " / ");
    write(l, n);
    writeline(output, l);
  end procedure progress;

  function is_01(v: std_ulogic_vector) return boolean is
  begin
    for i in v'range loop
      if v(i) /= '0' and v(i) /= '1' then
        return false;
      end if;
    end loop;
    return true;
  end function is_01;

  function is_01(v: unsigned) return boolean is
  begin
    return is_01(std_ulogic_vector(v));
  end function is_01;

  function is_01(v: signed) return boolean is
  begin
    return is_01(std_ulogic_vector(v));
  end function is_01;

	type std_ulogic2char_t is array(std_ulogic range <>) of character;
  constant std_ulogic2char: std_ulogic2char_t := ( 'U' => 'U', '0' => '0', '1' => '1', 'X' => 'X', 'L' => 'L', 'H' => 'H', 'W' => 'W', 'Z' => 'Z', '-' => '-');

	function hex2nat(c: character) return integer is
		variable res: integer range -1 to 15;
	begin
		case c is
			when '0' to '9' => res := character'pos(c) - character'pos('0');
			when 'a' to 'f' => res := 10 + character'pos(c) - character'pos('a');
			when 'A' to 'F' => res := 10 + character'pos(c) - character'pos('A');
			when others => res := -1;
		end case;
		return res;
	end function hex2nat;

	procedure hread(l: inout line; val: out bit_vector; good: out boolean) is
		variable tmp: unsigned(val'length - 1 downto 0);
	begin
		hread(l, tmp, good);
		val := to_bitvector(std_ulogic_vector(tmp));
	end procedure hread;

  procedure hread(l: inout line; val: out std_ulogic_vector;
	                good: out boolean) is
		variable tmp: unsigned(val'length - 1 downto 0);
	begin
		hread(l, tmp, good);
		val := std_ulogic_vector(tmp);
	end procedure hread;

	procedure hread(l: inout line; val: out signed; good: out boolean) is
		variable tmp: unsigned(val'length - 1 downto 0);
	begin
		hread(l, tmp, good);
		val := signed(std_ulogic_vector(tmp));
	end procedure hread;

  procedure hread(l: inout line; val: out unsigned; good: out boolean) is
    variable res: unsigned(val'length + 3 downto 0);
		variable n, s: integer;
		variable v: integer range -1 to 15;
		variable i: positive;
		variable c: character;
  begin
		res := (others => '0');
		good := false;
		i := 1;
		s := val'length;
		n := res'length - 1;
		-- skip leading spaces, tabs and carriage returns
		while l'length /= 0 and (l(1) = ' ' or l(1) = CR or l(1) = HT) loop
      read(l,c);
    end loop;
		loop
			exit when l'length < i; -- end of line
			v := hex2nat(l(i));
			exit when v = -1;       -- non-hex char
			exit when s < 0;        -- full res
			res(s + 3 downto s) := to_unsigned(v, 4);
			i := i + 1;
			s := s - 4;
		end loop;
		if i = 1 or (l'length >= i and v /= -1) then -- empty line or non-hex first
			return;                                    -- char or res overflow
		end if;
		res := shift_right(res, s + 4); -- right-align res
		if or_reduce(res(n downto n - 3)) /= '0' then -- res overflow
			return;
		end if;
		good := true;
		val := res(n - 4 downto 0);
		for j in 1 to i - 1 loop -- consume read chars
			read(l, c);
		end loop;
	end procedure hread;

	procedure hread(l: inout line; val: out natural; good: out boolean) is
		variable tmp: unsigned(30 downto 0);
	begin
		hread(l, tmp, good);
		val := to_integer(tmp);
	end procedure hread;

	procedure hread(l: inout line; val: out bit_vector) is
		variable good: boolean;
	begin
		hread(l, val, good);
	end procedure hread;

  procedure hread(l: inout line; val: out std_ulogic_vector) is
		variable good: boolean;
	begin
		hread(l, val, good);
	end procedure hread;

  procedure hread(l: inout line; val: out unsigned) is
		variable good: boolean;
	begin
		hread(l, val, good);
	end procedure hread;

  procedure hread(l: inout line; val: out signed) is
		variable good: boolean;
	begin
		hread(l, val, good);
	end procedure hread;

  procedure hread(l: inout line; val: out natural) is
		variable good: boolean;
	begin
		hread(l, val, good);
	end procedure hread;

	procedure dwrite(l: inout line; val: in bit_vector) is
  begin
    dwrite(l, unsigned(to_stdulogicvector(val)));
  end procedure dwrite;

	procedure hwrite(l: inout line; val: in bit_vector) is
	begin
		hwrite(l, unsigned(to_stdulogicvector(val)));
	end procedure hwrite;

	procedure dwrite(l: inout line; val: in std_ulogic_vector) is
	begin
		dwrite(l, unsigned(val));
	end procedure dwrite;

	procedure dwrite(l: inout line; val: in signed) is
	begin
		dwrite(l, unsigned(signed(val)));
	end procedure dwrite;

	procedure dwrite(l: inout line; val: in unsigned) is
  begin
    if val'length = 0 then
      return;
    elsif or_reduce(val) = '0' then
      write(l, 0);
      return;
    else
      dwrite(l, val / 10);
      write(l, to_integer(val mod 10));
    end if;
  end procedure dwrite;

 	procedure hwrite(l: inout line; val: in std_ulogic_vector) is
 	begin
 		hwrite(l, unsigned(val));
 	end procedure hwrite;

	procedure hwrite(l: inout line; val: in signed) is
	begin
		hwrite(l, unsigned(signed(val)));
	end procedure hwrite;

	procedure hwrite(l: inout line; val: in unsigned) is
		constant nat2hex: string(1 to 16) := "0123456789ABCDEF";
		constant n: positive := val'length;
		variable tmp: unsigned(n + 3 downto 0);
	begin
	  tmp := (others => '0');
	  tmp(n - 1 downto 0) := val;
	  for i in (n - 1) / 4 downto 0 loop
      if is_01(tmp(4 * i + 3 downto 4 * i)) then
		    write(l, nat2hex(to_integer(tmp(4 * i + 3 downto 4 * i)) + 1));
      else
		    print(l, "X");
      end if;
	  end loop;
	end procedure hwrite;

	procedure write(l: inout line; val: in unsigned) is
	begin
		write(l, std_ulogic_vector(val));
	end procedure write;

	procedure write(l: inout line; val: in signed) is
	begin
		write(l, std_ulogic_vector(val));
	end procedure write;

  procedure print(l: inout line; val: in string) is
  begin
    write(l, string'(val));
  end procedure print;

  procedure print(val: in string) is
    variable l: line;
  begin
    write(l, string'(val));
    writeline(output, l);
  end procedure print;

	procedure write(l: inout line; val: in std_ulogic) is
	begin
		write(l, std_ulogic2char(val));
	end procedure write;

 	procedure write(l: inout line; val: in std_ulogic_vector) is
 		constant n: natural := val'length;
 		constant tmp: std_ulogic_vector(0 to n - 1) := val;
 	begin
 		for i in 0 to n - 1 loop
 			write(l, tmp(i));
 		end loop;
 	end procedure write;

  function char2dec(c: character) return integer is
		variable res: integer range -1 to 9;
  begin
    case c is
      when '0' to '9' => res := character'pos(c) - character'pos('0');
      when others => res := -1;
    end case;
    return res;
  end function char2dec;

  function char2bin(c: character) return integer is
		variable res: integer range -1 to 1;
  begin
    case c is
      when '0' => res := 0;
      when '1' => res := 1;
      when others => res := -1;
    end case;
    return res;
  end function char2bin;

  function char2hex(c: character) return integer is
		variable res: integer range -1 to 15;
  begin
    case c is
      when '0' to '9' => res := character'pos(c) - character'pos('0');
      when 'a' to 'f' => res := character'pos(c) - character'pos('a') + 10;
      when 'A' to 'F' => res := character'pos(c) - character'pos('A') + 10;
      when others => res := -1;
    end case;
    return res;
  end function char2hex;

	function masked_check(mask: std_ulogic_vector; exp: std_ulogic_vector; got: std_ulogic_vector) return boolean is
		variable m: std_ulogic_vector(0 to mask'length - 1) := mask;
		variable e: std_ulogic_vector(0 to exp'length - 1) := exp;
		variable g: std_ulogic_vector(0 to got'length - 1) := got;
  begin
		assert e'length = g'length and e'length = 8 * m'length
		  report "masked_check: invalid parameters lengths"
			severity failure;
    for i in 0 to 7 loop
			if m(i) = '1' and
			  e(8 * i to 8 * i + 7) /= g(8 * i to 8 * i + 7) then
        return false;
			end if;
    end loop;
		return true;
	end function masked_check;

  function vector_check(a, b: std_ulogic_vector) return boolean is
    constant dc: std_ulogic_vector(a'length - 1 downto 0) := (others => '-');
    variable res: boolean := true;
  begin
    if a'length /= b'length then
      res := false;
    elsif a /= dc and b /= dc and a /= b then
      res := false;
    end if;
    return res;
  end function vector_check;

  function vec2hexstr(val: std_ulogic_vector) return string is
    variable n: integer := (val'length + 3) / 4;
    variable v: std_ulogic_vector(0 to 4 * n - 1) := (others => '0');
    variable res: string(1 to n);
  begin
    assert val'length /= 0
      report "vec2hexstr: zero length error"
      severity failure;
    v(4 * n - val'length to 4 * n - 1) := val;
    for i in 0 to n - 1 loop
      res(1 + i) := hex2char(1 + to_integer(unsigned(v(4 * i to 4 * i + 3))));
    end loop;
    return res;
  end function vec2hexstr;

  type shared_natural is protected body
    variable n: natural;
    impure function get return natural is
    begin
      return n;
    end function get;
    procedure inc is
    begin
      n := n + 1;
    end procedure inc;
  end protected body shared_natural;

end package body sim_utils;
