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
use ieee.numeric_std.all;
use work.inception_pkg.all;
USE std.textio.all;
use ieee.std_logic_textio.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity P_ODDR2 is
port (
    aclk       : in std_logic;
    clk_out    : out std_logic;
    aresetn    : in std_logic
);
end P_ODDR2;

architecture beh of P_ODDR2 is

  component ODDR2
  port(
          D0	: in std_logic;
          D1	: in std_logic;
          C0	: in std_logic;
          C1	: in std_logic;
          Q	: out std_logic;
          CE    : in std_logic;
          S     : in std_logic;
          R	: in std_logic
    );
  end component;

  signal aclkn: std_logic;

begin

 --clk_out_syn_gen: generate
   aclkn <= not aclk;
   oddr_inst : ODDR2
     port map (
       D0     => '0',
       D1     => '1',
       C0     => aclk,
       C1     => aclkn,
       Q      => clk_out,
       CE     => aresetn,
       S      => '0',
       R      => '0'
     );
  --end generate clk_out_syn_gen;

end beh;

