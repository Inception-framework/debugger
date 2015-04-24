--
-- SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
-- Copyright (C) 2015 - Telecom ParisTech
-- 
-- This file must be used under the terms of the CeCILL.
-- This source file is licensed as described in the file COPYING, which
-- you should have received as part of this distribution.  The terms
-- are also available at    
-- http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
--

library ieee;
use ieee.std_logic_1164.all;

library axi_lib;
use axi_lib.axi_pkg.all;

entity axi_register_wrapper is
  port(
    aclk:       in std_logic;
    aresetn:    in std_logic;
    --------------------------------
    -- AXI lite slave port s_axi --
    --------------------------------
    -- Inputs (master to slave) --
    ------------------------------
    -- Read address channel
    s_axi_araddr:  in  std_logic_vector(11 downto 0);
    s_axi_arprot:  in  std_logic_vector(2 downto 0);
    s_axi_arvalid: in  std_logic;
    -- Read data channel
    s_axi_rready:  in  std_logic;
    -- Write address channel
    s_axi_awaddr:  in  std_logic_vector(11 downto 0);
    s_axi_awprot:  in  std_logic_vector(2 downto 0);
    s_axi_awvalid: in  std_logic;
    -- Write data channel
    s_axi_wdata:   in  std_logic_vector(31 downto 0);
    s_axi_wstrb:   in  std_logic_vector(3 downto 0);
    s_axi_wvalid:  in  std_logic;
    -- Write response channel
    s_axi_bready:  in  std_logic;
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    s_axi_arready: out std_logic;
    -- Read data channel
    s_axi_rdata:   out std_logic_vector(31 downto 0);
    s_axi_rresp:   out std_logic_vector(1 downto 0);
    s_axi_rvalid:  out std_logic;
    -- Write address channel
    s_axi_awready: out std_logic;
    -- Write data channel
    s_axi_wready:  out std_logic;
    -- Write response channel
    s_axi_bvalid:  out std_logic;
    s_axi_bresp:   out std_logic_vector(1 downto 0);

    -- GPIO
    gpi:        in  std_logic_vector(7 downto 0);
    gpo:        out std_logic_vector(7 downto 0)
  );
end entity axi_register_wrapper;

architecture rtl of axi_register_wrapper is

    signal s_axi_m2s: axilite_gp_m2s;
    signal s_axi_s2m: axilite_gp_s2m;
    signal gpi_local: std_ulogic_vector(7 downto 0);
    signal gpo_local: std_ulogic_vector(7 downto 0);

begin

  i_axi_register: entity work.axi_register
  port map(
    aclk       => aclk,
    aresetn    => aresetn,
    s_axi_m2s  => s_axi_m2s,
    s_axi_s2m  => s_axi_s2m,
    gpi        => gpi_local,
    gpo        => gpo_local
  );

  s_axi_m2s.araddr  <= std_ulogic_vector(X"00000" & s_axi_araddr);
  s_axi_m2s.arprot  <= std_ulogic_vector(s_axi_arprot);
  s_axi_m2s.arvalid <= s_axi_arvalid;

  s_axi_m2s.rready  <= s_axi_rready;

  s_axi_m2s.awaddr  <= std_ulogic_vector(X"00000" & s_axi_awaddr);
  s_axi_m2s.awprot  <= std_ulogic_vector(s_axi_awprot);
  s_axi_m2s.awvalid <= s_axi_awvalid;

  s_axi_m2s.wdata   <= std_ulogic_vector(s_axi_wdata);
  s_axi_m2s.wstrb   <= std_ulogic_vector(s_axi_wstrb);
  s_axi_m2s.wvalid  <= s_axi_wvalid;

  s_axi_m2s.bready  <= s_axi_bready;

  s_axi_arready     <= s_axi_s2m.arready;

  s_axi_rdata       <= std_logic_vector(s_axi_s2m.rdata);
  s_axi_rresp       <= std_logic_vector(s_axi_s2m.rresp);
  s_axi_rvalid      <= s_axi_s2m.rvalid;

  s_axi_awready     <= s_axi_s2m.awready;

  s_axi_wready      <= s_axi_s2m.wready;

  s_axi_bvalid      <= s_axi_s2m.bvalid;
  s_axi_bresp       <= std_logic_vector(s_axi_s2m.bresp);

  gpi_local         <= std_ulogic_vector(gpi);
  gpo               <= std_logic_vector(gpo_local);

end architecture rtl;
