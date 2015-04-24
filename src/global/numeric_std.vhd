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

package numeric_std is

  --============================================================================
  -- numeric array type definitions
  --============================================================================

  type unsigned is array(natural range <>) of std_ulogic;
  type signed is array(natural range <>) of std_ulogic;

  --============================================================================
  -- arithmetic operators:
  --===========================================================================

  -- id: a.1
  function "abs" (arg: signed) return signed;
  -- result subtype: signed(arg'length-1 downto 0).
  -- result: returns the absolute value of a signed vector arg.

  -- id: a.2
  function "-" (arg: signed) return signed;
  -- result subtype: signed(arg'length-1 downto 0).
  -- result: returns the value of the unary minus operation on a
  --         signed vector arg.
  
  -- id: a.3
  function "+" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(max(l'length, r'length)-1 downto 0).
  -- result: adds two unsigned vectors that may be of different lengths.

  -- id: a.4
  function "+" (l, r: signed) return signed;
  -- result subtype: signed(max(l'length, r'length)-1 downto 0).
  -- result: adds two signed vectors that may be of different lengths.

  -- id: a.5
  function "+" (l: unsigned; r: natural) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0).
  -- result: adds an unsigned vector, l, with a non-negative integer, r.

  -- id: a.6
  function "+" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0).
  -- result: adds a non-negative integer, l, with an unsigned vector, r.

  -- id: a.7
  function "+" (l: integer; r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0).
  -- result: adds an integer, l(may be positive or negative), to a signed
  --         vector, r.

  -- id: a.8
  function "+" (l: signed; r: integer) return signed;
  -- result subtype: signed(l'length-1 downto 0).
  -- result: adds a signed vector, l, to an integer, r.

  --============================================================================

  -- id: a.9
  function "-" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(max(l'length, r'length)-1 downto 0).
  -- result: subtracts two unsigned vectors that may be of different lengths.

  -- id: a.10
  function "-" (l, r: signed) return signed;
  -- result subtype: signed(max(l'length, r'length)-1 downto 0).
  -- result: subtracts a signed vector, r, from another signed vector, l,
  --         that may possibly be of different lengths.

  -- id: a.11
  function "-" (l: unsigned;r: natural) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0).
  -- result: subtracts a non-negative integer, r, from an unsigned vector, l.

  -- id: a.12
  function "-" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0).
  -- result: subtracts an unsigned vector, r, from a non-negative integer, l.

  -- id: a.13
  function "-" (l: signed; r: integer) return signed;
  -- result subtype: signed(l'length-1 downto 0).
  -- result: subtracts an integer, r, from a signed vector, l.

  -- id: a.14
  function "-" (l: integer; r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0).
  -- result: subtracts a signed vector, r, from an integer, l.

  --============================================================================

  -- id: a.15
  function "*" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned((l'length+r'length-1) downto 0).
  -- result: performs the multiplication operation on two unsigned vectors
  --         that may possibly be of different lengths.

  -- id: a.16
  function "*" (l, r: signed) return signed;
  -- result subtype: signed((l'length+r'length-1) downto 0)
  -- result: multiplies two signed vectors that may possibly be of
  --         different lengths.

  -- id: a.17
  function "*" (l: unsigned; r: natural) return unsigned;
  -- result subtype: unsigned((l'length+l'length-1) downto 0).
  -- result: multiplies an unsigned vector, l, with a non-negative
  --         integer, r. r is converted to an unsigned vector of
  --         size l'length before multiplication.

  -- id: a.18
  function "*" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned((r'length+r'length-1) downto 0).
  -- result: multiplies an unsigned vector, r, with a non-negative
  --         integer, l. l is converted to an unsigned vector of
  --         size r'length before multiplication.

  -- id: a.19
  function "*" (l: signed; r: integer) return signed;
  -- result subtype: signed((l'length+l'length-1) downto 0)
  -- result: multiplies a signed vector, l, with an integer, r. r is
  --         converted to a signed vector of size l'length before
  --         multiplication.

  -- id: a.20
  function "*" (l: integer; r: signed) return signed;
  -- result subtype: signed((r'length+r'length-1) downto 0)
  -- result: multiplies a signed vector, r, with an integer, l. l is
  --         converted to a signed vector of size r'length before
  --         multiplication.

  --============================================================================
  --
  -- note: if second argument is zero for "/" operator, a severity level
  --       of error is issued.

  -- id: a.21
  function "/" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: divides an unsigned vector, l, by another unsigned vector, r.

  -- id: a.22
  function "/" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: divides an signed vector, l, by another signed vector, r.

  -- id: a.23
  function "/" (l: unsigned; r: natural) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: divides an unsigned vector, l, by a non-negative integer, r.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.24
  function "/" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0)
  -- result: divides a non-negative integer, l, by an unsigned vector, r.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  -- id: a.25
  function "/" (l: signed; r: integer) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: divides a signed vector, l, by an integer, r.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.26
  function "/" (l: integer; r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0)
  -- result: divides an integer, l, by a signed vector, r.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  --============================================================================
  --
  -- note: if second argument is zero for "rem" operator, a severity level
  --       of error is issued.

  -- id: a.27
  function "rem" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0)
  -- result: computes "l rem r" where l and r are unsigned vectors.

  -- id: a.28
  function "rem" (l, r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0)
  -- result: computes "l rem r" where l and r are signed vectors.

  -- id: a.29
  function "rem" (l: unsigned; r: natural) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: computes "l rem r" where l is an unsigned vector and r is a
  --         non-negative integer.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.30
  function "rem" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0)
  -- result: computes "l rem r" where r is an unsigned vector and l is a
  --         non-negative integer.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  -- id: a.31
  function "rem" (l: signed; r: integer) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: computes "l rem r" where l is signed vector and r is an integer.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.32
  function "rem" (l: integer; r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0)
  -- result: computes "l rem r" where r is signed vector and l is an integer.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  --============================================================================
  --
  -- note: if second argument is zero for "mod" operator, a severity level
  --       of error is issued.

  -- id: a.33
  function "mod" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0)
  -- result: computes "l mod r" where l and r are unsigned vectors.

  -- id: a.34
  function "mod" (l, r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0)
  -- result: computes "l mod r" where l and r are signed vectors.

  -- id: a.35
  function "mod" (l: unsigned; r: natural) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: computes "l mod r" where l is an unsigned vector and r
  --         is a non-negative integer.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.36
  function "mod" (l: natural; r: unsigned) return unsigned;
  -- result subtype: unsigned(r'length-1 downto 0)
  -- result: computes "l mod r" where r is an unsigned vector and l
  --         is a non-negative integer.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  -- id: a.37
  function "mod" (l: signed; r: integer) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: computes "l mod r" where l is a signed vector and
  --         r is an integer.
  --         if no_of_bits(r) > l'length, result is truncated to l'length.

  -- id: a.38
  function "mod" (l: integer; r: signed) return signed;
  -- result subtype: signed(r'length-1 downto 0)
  -- result: computes "l mod r" where l is an integer and
  --         r is a signed vector.
  --         if no_of_bits(l) > r'length, result is truncated to r'length.

  --============================================================================
  -- comparison operators
  --============================================================================

  -- id: c.1
  function ">" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.2
  function ">" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.3
  function ">" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.4
  function ">" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l is a integer and
  --         r is a signed vector.

  -- id: c.5
  function ">" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.6
  function ">" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l > r" where l is a signed vector and
  --         r is a integer.

  --============================================================================

  -- id: c.7
  function "<" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.8
  function "<" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.9
  function "<" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.10
  function "<" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l is an integer and
  --         r is a signed vector.

  -- id: c.11
  function "<" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.12
  function "<" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l < r" where l is a signed vector and
  --         r is an integer.

  --============================================================================

  -- id: c.13
  function "<=" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.14
  function "<=" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.15
  function "<=" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.16
  function "<=" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l is an integer and
  --         r is a signed vector.

  -- id: c.17
  function "<=" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.18
  function "<=" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l <= r" where l is a signed vector and
  --         r is an integer.

  --============================================================================

  -- id: c.19
  function ">=" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.20
  function ">=" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.21
  function ">=" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.22
  function ">=" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l is an integer and
  --         r is a signed vector.

  -- id: c.23
  function ">=" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.24
  function ">=" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l >= r" where l is a signed vector and
  --         r is an integer.

  --============================================================================

  -- id: c.25
  function "=" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.26
  function "=" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.27
  function "=" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.28
  function "=" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l is an integer and
  --         r is a signed vector.

  -- id: c.29
  function "=" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.30
  function "=" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l = r" where l is a signed vector and
  --         r is an integer.

  --============================================================================

  -- id: c.31
  function "/=" (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l and r are unsigned vectors possibly
  --         of different lengths.

  -- id: c.32
  function "/=" (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l and r are signed vectors possibly
  --         of different lengths.

  -- id: c.33
  function "/=" (l: natural; r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l is a non-negative integer and
  --         r is an unsigned vector.

  -- id: c.34
  function "/=" (l: integer; r: signed) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l is an integer and
  --         r is a signed vector.

  -- id: c.35
  function "/=" (l: unsigned; r: natural) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l is an unsigned vector and
  --         r is a non-negative integer.

  -- id: c.36
  function "/=" (l: signed; r: integer) return boolean;
  -- result subtype: boolean
  -- result: computes "l /= r" where l is a signed vector and
  --         r is an integer.

  --============================================================================
  -- shift and rotate functions
  --============================================================================

  -- id: s.1
  function shift_left (arg: unsigned; count: natural) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: performs a shift-left on an unsigned vector count times.
  --         the vacated positions are filled with '0'.
  --         the count leftmost elements are lost.

  -- id: s.2
  function shift_right (arg: unsigned; count: natural) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: performs a shift-right on an unsigned vector count times.
  --         the vacated positions are filled with '0'.
  --         the count rightmost elements are lost.

  -- id: s.3
  function shift_left (arg: signed; count: natural) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: performs a shift-left on a signed vector count times.
  --         the vacated positions are filled with '0'.
  --         the count leftmost elements are lost.

  -- id: s.4
  function shift_right (arg: signed; count: natural) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: performs a shift-right on a signed vector count times.
  --         the vacated positions are filled with the leftmost
  --         element, arg'left. the count rightmost elements are lost.

  --============================================================================

  -- id: s.5
  function rotate_left (arg: unsigned; count: natural) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: performs a rotate-left of an unsigned vector count times.

  -- id: s.6
  function rotate_right (arg: unsigned; count: natural) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: performs a rotate-right of an unsigned vector count times.

  -- id: s.7
  function rotate_left (arg: signed; count: natural) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: performs a logical rotate-left of a signed
  --         vector count times.

  -- id: s.8
  function rotate_right (arg: signed; count: natural) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: performs a logical rotate-right of a signed
  --         vector count times.

  --============================================================================

  --============================================================================

  ------------------------------------------------------------------------------
  --   note : function s.9 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.9
  function "sll" (arg: unsigned; count: integer) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: shift_left(arg, count)

  ------------------------------------------------------------------------------
  -- note : function s.10 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.10
  function "sll" (arg: signed; count: integer) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: shift_left(arg, count)

  ------------------------------------------------------------------------------
  --   note : function s.11 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.11
  function "srl" (arg: unsigned; count: integer) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: shift_right(arg, count)

  ------------------------------------------------------------------------------
  --   note : function s.12 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.12
  function "srl" (arg: signed; count: integer) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: signed(shift_right(unsigned(arg), count))

  ------------------------------------------------------------------------------
  --   note : function s.13 is not compatible with vhdl 1076-1987. comment
  -- out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.13
  function "rol" (arg: unsigned; count: integer) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: rotate_left(arg, count)

  ------------------------------------------------------------------------------
  --   note : function s.14 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.14
  function "rol" (arg: signed; count: integer) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: rotate_left(arg, count)

  ------------------------------------------------------------------------------
  -- note : function s.15 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.15
  function "ror" (arg: unsigned; count: integer) return unsigned;
  -- result subtype: unsigned(arg'length-1 downto 0)
  -- result: rotate_right(arg, count)

  ------------------------------------------------------------------------------
  --   note : function s.16 is not compatible with vhdl 1076-1987. comment
  --   out the function (declaration and body) for vhdl 1076-1987 compatibility.
  ------------------------------------------------------------------------------
  -- id: s.16
  function "ror" (arg: signed; count: integer) return signed;
  -- result subtype: signed(arg'length-1 downto 0)
  -- result: rotate_right(arg, count)

  --============================================================================
  --   resize functions
  --============================================================================

  -- id: r.1
  function resize (arg: signed; new_size: natural) return signed;
  -- result subtype: signed(new_size-1 downto 0)
  -- result: resizes the signed vector arg to the specified size.
  --         to create a larger vector, the new [leftmost] bit positions
  --         are filled with the sign bit (arg'left). when truncating,
  --         the sign bit is retained along with the rightmost part.

  -- id: r.2
  function resize (arg: unsigned; new_size: natural) return unsigned;
  -- result subtype: unsigned(new_size-1 downto 0)
  -- result: resizes the signed vector arg to the specified size.
  --         to create a larger vector, the new [leftmost] bit positions
  --         are filled with '0'. when truncating, the leftmost bits
  --         are dropped.

  --============================================================================
  -- conversion functions
  --============================================================================

  -- id: d.1
  function to_integer (arg: unsigned) return natural;
  -- result subtype: natural. value cannot be negative since parameter is an
  --             unsigned vector.
  -- result: converts the unsigned vector to an integer.

  -- id: d.2
  function to_integer (arg: signed) return integer;
  -- result subtype: integer
  -- result: converts a signed vector to an integer.

  -- id: d.3
  function to_unsigned (arg, size: natural) return unsigned;
  -- result subtype: unsigned(size-1 downto 0)
  -- result: converts a non-negative integer to an unsigned vector with
  --         the specified size.

  -- id: d.4
  function to_signed (arg: integer; size: natural) return signed;
  -- result subtype: signed(size-1 downto 0)
  -- result: converts an integer to a signed vector of the specified size.

  --============================================================================
  -- logical operators
  --============================================================================

  -- id: l.1
  function "not" (l: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: termwise inversion

  -- id: l.2
  function "and" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector and operation

  -- id: l.3
  function "or" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector or operation

  -- id: l.4
  function "nand" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector nand operation

  -- id: l.5
  function "nor" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector nor operation

  -- id: l.6
  function "xor" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector xor operation

  -- ---------------------------------------------------------------------------
  -- note : function l.7 is not compatible with vhdl 1076-1987. comment
  -- out the function (declaration and body) for vhdl 1076-1987 compatibility.
  -- ---------------------------------------------------------------------------
  -- id: l.7
  function "xnor" (l, r: unsigned) return unsigned;
  -- result subtype: unsigned(l'length-1 downto 0)
  -- result: vector xnor operation

  -- id: l.8
  function "not" (l: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: termwise inversion

  -- id: l.9
  function "and" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector and operation

  -- id: l.10
  function "or" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector or operation

  -- id: l.11
  function "nand" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector nand operation

  -- id: l.12
  function "nor" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector nor operation

  -- id: l.13
  function "xor" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector xor operation

  -- ---------------------------------------------------------------------------
  -- note : function l.14 is not compatible with vhdl 1076-1987. comment
  -- out the function (declaration and body) for vhdl 1076-1987 compatibility.
  -- ---------------------------------------------------------------------------
  -- id: l.14
  function "xnor" (l, r: signed) return signed;
  -- result subtype: signed(l'length-1 downto 0)
  -- result: vector xnor operation

  --============================================================================
  -- match functions
  --============================================================================

  -- id: m.2
  function std_match (l, r: unsigned) return boolean;
  -- result subtype: boolean
  -- result: terms compared per std_logic_1164 intent

  -- id: m.3
  function std_match (l, r: signed) return boolean;
  -- result subtype: boolean
  -- result: terms compared per std_logic_1164 intent

  --============================================================================
  -- translation functions
  --============================================================================

  -- id: t.1
  function to_01 (s: unsigned; xmap: std_logic := '0') return unsigned;
  -- result subtype: unsigned(s'range)
  -- result: termwise, 'h' is translated to '1', and 'l' is translated
  --         to '0'. if a value other than '0'|'1'|'h'|'l' is found,
  --         the array is set to (others => xmap), and a warning is
  --         issued.

  -- id: t.2
  function to_01 (s: signed; xmap: std_logic := '0') return signed;
  -- result subtype: signed(s'range)
  -- result: termwise, 'h' is translated to '1', and 'l' is translated
  --         to '0'. if a value other than '0'|'1'|'h'|'l' is found,
  --         the array is set to (others => xmap), and a warning is
  --         issued.

end package numeric_std;

--==============================================================================
--============================= package body ===================================
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- all the functions & operators defined above are
                          -- mere wrappers around their corresponding ieee.numeric_std
                          -- functions - that's why we need the numeric_std package
                          -- for the package body.

package body numeric_std is

  --=========================exported functions ==========================

  -- id: a.1
  function "abs" (arg: signed) return signed is
  begin
    return signed(abs(ieee.numeric_std.signed(arg)));
  end "abs";

  -- id: a.2
  function "-" (arg: signed) return signed is
  begin
    return signed(-(ieee.numeric_std.signed(arg)));
  end function;

  -- id: a.3
  function "+" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) + ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.4
  function "+" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l)+ieee.numeric_std.signed(r));
  end function "+";

  -- id: a.5
  function "+" (l: unsigned; r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) + r);
  end function;

  -- id: a.6
  function "+" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l + ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.7
  function "+" (l: integer; r: signed) return signed is
  begin
    return signed(l + ieee.numeric_std.signed(r));
  end function;

  -- id: a.8
  function "+" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) + r);
  end function;

  -- id: a.9
  function "-" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) - ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.10
  function "-" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) - ieee.numeric_std.signed(r));
  end function;

  -- id: a.11
  function "-" (l: unsigned;r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) - r);
  end function;

  -- id: a.12
  function "-" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l - ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.13
  function "-" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) - r);
  end function;

  -- id: a.14
  function "-" (l: integer; r: signed) return signed is
  begin
    return signed(l - ieee.numeric_std.signed(r));
  end function;

  -- id: a.15
  function "*" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) * ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.16
  function "*" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) * ieee.numeric_std.signed(r));
  end function;

  -- id: a.17
  function "*" (l: unsigned; r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) * r);
  end function;

  -- id: a.18
  function "*" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l * ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.19
  function "*" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) * r);
  end function;

  -- id: a.20
  function "*" (l: integer; r: signed) return signed is
  begin
    return signed(l * ieee.numeric_std.signed(r));
  end function;

  -- id: a.21
  function "/" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) / ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.22
  function "/" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) / ieee.numeric_std.signed(r));
  end function;

  -- id: a.23
  function "/" (l: unsigned; r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) / r);
  end function;

  -- id: a.24
  function "/" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l / ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.25
  function "/" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) / r);
  end function;

  -- id: a.26
  function "/" (l: integer; r: signed) return signed is
  begin
    return signed(l / ieee.numeric_std.signed(r));
  end function;

  -- id: a.27
  function "rem" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) rem ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.28
  function "rem" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) rem ieee.numeric_std.signed(r));
  end function;

  -- id: a.29
  function "rem" (l: unsigned; r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) rem r);
  end function;

  -- id: a.30
  function "rem" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l rem ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.31
  function "rem" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) rem r);
  end function;

  -- id: a.32
  function "rem" (l: integer; r: signed) return signed is
  begin
    return signed(l rem ieee.numeric_std.signed(r));
  end function;

  -- id: a.33
  function "mod" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) mod ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.34
  function "mod" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) mod ieee.numeric_std.signed(r));
  end function;

  -- id: a.35
  function "mod" (l: unsigned; r: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) mod r);
  end function;

  -- id: a.36
  function "mod" (l: natural; r: unsigned) return unsigned is
  begin
    return unsigned(l mod ieee.numeric_std.unsigned(r));
  end function;

  -- id: a.37
  function "mod" (l: signed; r: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) mod r);
  end function;

  -- id: a.38
  function "mod" (l: integer; r: signed) return signed is
  begin
    return signed(l mod ieee.numeric_std.signed(r));
  end function;

  -- id: c.1
  function ">" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) > ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.2
  function ">" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) > ieee.numeric_std.signed(r));
  end function;

  -- id: c.3
  function ">" (l: natural; r: unsigned) return boolean is
  begin
    return (l > ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.4
  function ">" (l: integer; r: signed) return boolean is
  begin
    return (l > ieee.numeric_std.signed(r));
  end function;

  -- id: c.5
  function ">" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) > r);
  end function;

  -- id: c.6
  function ">" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) > r);
  end function;

  -- id: c.7
  function "<" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) < ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.8
  function "<" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) < ieee.numeric_std.signed(r));
  end function;

  -- id: c.9
  function "<" (l: natural; r: unsigned) return boolean is
  begin
    return (l < ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.10
  function "<" (l: integer; r: signed) return boolean is
  begin
    return (l < ieee.numeric_std.signed(r));
  end function;

  -- id: c.11
  function "<" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) < r);
  end function;

  -- id: c.12
  function "<" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) < r);
  end function;

  -- id: c.13
  function "<=" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) <= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.14
  function "<=" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) <= ieee.numeric_std.signed(r));
  end function;

  -- id: c.15
  function "<=" (l: natural; r: unsigned) return boolean is
  begin
    return (l <= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.16
  function "<=" (l: integer; r: signed) return boolean is
  begin
    return (l <= ieee.numeric_std.signed(r));
  end function;

  -- id: c.17
  function "<=" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) <= r);
  end function;

  -- id: c.18
  function "<=" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) <= r);
  end function;

  -- id: c.19
  function ">=" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) >= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.20
  function ">=" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) >= ieee.numeric_std.signed(r));
  end function;

  -- id: c.21
  function ">=" (l: natural; r: unsigned) return boolean is
  begin
    return (l >= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.22
  function ">=" (l: integer; r: signed) return boolean is
  begin
    return (l >= ieee.numeric_std.signed(r));
  end function;

  -- id: c.23
  function ">=" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) >= r);
  end function;

  -- id: c.24
  function ">=" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) >= r);
  end function;

  -- id: c.25
  function "=" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) = ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.26
  function "=" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) = ieee.numeric_std.signed(r));
  end function;

  -- id: c.27
  function "=" (l: natural; r: unsigned) return boolean is
  begin
    return (l = ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.28
  function "=" (l: integer; r: signed) return boolean is
  begin
    return (l = ieee.numeric_std.signed(r));
  end function;

  -- id: c.29
  function "=" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) = r);
  end function;

  -- id: c.30
  function "=" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) = r);
  end function;

  -- id: c.31
  function "/=" (l, r: unsigned) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) /= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.32
  function "/=" (l, r: signed) return boolean is
  begin
    return (ieee.numeric_std.signed(l) /= ieee.numeric_std.signed(r));
  end function;

  -- id: c.33
  function "/=" (l: natural; r: unsigned) return boolean is
  begin
    return (l /= ieee.numeric_std.unsigned(r));
  end function;

  -- id: c.34
  function "/=" (l: integer; r: signed) return boolean is
  begin
    return (l /= ieee.numeric_std.signed(r));
  end function;

  -- id: c.35
  function "/=" (l: unsigned; r: natural) return boolean is
  begin
    return (ieee.numeric_std.unsigned(l) /= r);
  end function;

  -- id: c.36
  function "/=" (l: signed; r: integer) return boolean is
  begin
    return (ieee.numeric_std.signed(l) /= r);
  end function;

  -- id: s.1
  function shift_left (arg: unsigned; count: natural) return unsigned is
  begin
    return unsigned(shift_left(ieee.numeric_std.unsigned(arg), count));
  end function;

  -- id: s.2
  function shift_right (arg: unsigned; count: natural) return unsigned is
  begin
    return unsigned(shift_right(ieee.numeric_std.unsigned(arg), count));
  end function;

  -- id: s.3
  function shift_left (arg: signed; count: natural) return signed is
  begin
    return signed(shift_left(ieee.numeric_std.signed(arg), count));
  end function;

  -- id: s.4
  function shift_right (arg: signed; count: natural) return signed is
  begin
    return signed(shift_right(ieee.numeric_std.signed(arg), count));
  end function;

  -- id: s.5
  function rotate_left (arg: unsigned; count: natural) return unsigned is
  begin
    return unsigned(rotate_left(ieee.numeric_std.unsigned(arg), count));
  end function;

  -- id: s.6
  function rotate_right (arg: unsigned; count: natural) return unsigned is
  begin
    return unsigned(rotate_right(ieee.numeric_std.unsigned(arg), count));
  end function;

  -- id: s.7
  function rotate_left (arg: signed; count: natural) return signed is
  begin
    return signed(rotate_left(ieee.numeric_std.signed(arg), count));
  end function;

  -- id: s.8
  function rotate_right (arg: signed; count: natural) return signed is
  begin
    return signed(rotate_right(ieee.numeric_std.signed(arg), count));
  end function;

  -- id: s.9
  function "sll" (arg: unsigned; count: integer) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(arg) sll count);
  end function;

  -- id: s.10
  function "sll" (arg: signed; count: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(arg) sll count);
  end function;

  -- id: s.11
  function "srl" (arg: unsigned; count: integer) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(arg) srl count);
  end function;

  -- id: s.12
  function "srl" (arg: signed; count: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(arg) srl count);
  end function;

  -- id: s.13
  function "rol" (arg: unsigned; count: integer) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(arg) rol count);
  end function;

  -- id: s.14
  function "rol" (arg: signed; count: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(arg) rol count);
  end function;

  -- id: s.15
  function "ror" (arg: unsigned; count: integer) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(arg) ror count);
  end function;

  -- id: s.16
  function "ror" (arg: signed; count: integer) return signed is
  begin
    return signed(ieee.numeric_std.signed(arg) ror count);
  end function;

  -- id: r.1
  function resize (arg: signed; new_size: natural) return signed is
  begin
    return signed(resize(ieee.numeric_std.signed(arg), new_size));
  end function;

  -- id: r.2
  function resize (arg: unsigned; new_size: natural) return unsigned is
  begin
    return unsigned(resize(ieee.numeric_std.unsigned(arg), new_size));
  end function;

  -- id: d.1
  function to_integer (arg: unsigned) return natural is
  begin
    return to_integer(ieee.numeric_std.unsigned(arg));
  end function;

  -- id: d.2
  function to_integer (arg: signed) return integer is
  begin
    return to_integer(ieee.numeric_std.signed(arg));
  end function;

  -- id: d.3
  function to_unsigned (arg, size: natural) return unsigned is
  begin
    return unsigned(ieee.numeric_std.to_unsigned(arg, size));
  end function;

  -- id: d.4
  function to_signed (arg: integer; size: natural) return signed is
  begin
    return signed(ieee.numeric_std.to_signed(arg, size));
  end function;

  -- id: l.1
  function "not" (l: unsigned) return unsigned is
  begin
    return unsigned(not ieee.numeric_std.unsigned(l));
  end function;

  -- id: l.2
  function "and" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) and ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.3
  function "or" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) or ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.4
  function "nand" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) nand ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.5
  function "nor" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) nor ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.6
  function "xor" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) xor ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.7
  function "xnor" (l, r: unsigned) return unsigned is
  begin
    return unsigned(ieee.numeric_std.unsigned(l) xnor ieee.numeric_std.unsigned(r));
  end function;

  -- id: l.8
  function "not" (l: signed) return signed is
  begin
    return signed(not ieee.numeric_std.signed(l));
  end function;

  -- id: l.9
  function "and" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) and ieee.numeric_std.signed(r));
  end function;

  -- id: l.10
  function "or" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) or ieee.numeric_std.signed(r));
  end function;

  -- id: l.11
  function "nand" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) nand ieee.numeric_std.signed(r));
  end function;

  -- id: l.12
  function "nor" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) nor ieee.numeric_std.signed(r));
  end function;

  -- id: l.13
  function "xor" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) xor ieee.numeric_std.signed(r));
  end function;

  -- id: l.14
  function "xnor" (l, r: signed) return signed is
  begin
    return signed(ieee.numeric_std.signed(l) xnor ieee.numeric_std.signed(r));
  end function;

  -- id: m.2
  function std_match (l, r: unsigned) return boolean is
  begin
    return std_match(ieee.numeric_std.unsigned(l), ieee.numeric_std.unsigned(r));
  end function;

  -- id: m.3
  function std_match (l, r: signed) return boolean is
  begin
    return std_match(ieee.numeric_std.signed(l), ieee.numeric_std.signed(r));
  end function;

  -- id: t.1
  function to_01 (s: unsigned; xmap: std_logic := '0') return unsigned is
  begin
    return unsigned(to_01(ieee.numeric_std.unsigned(s), xmap));
  end function;

  -- id: t.2
  function to_01 (s: signed; xmap: std_logic := '0') return signed is
  begin
    return signed(to_01(ieee.numeric_std.signed(s), xmap));
  end function;


end package body;
