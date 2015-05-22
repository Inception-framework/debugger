--
-- Copyright (C) Telecom ParisTech
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
    -- AXI lite slave port s0_axi --
    --------------------------------
    -- Inputs (master to slave) --
    ------------------------------
    -- Read address channel
    s0_axi_araddr:  in  std_logic_vector(11 downto 0);
    s0_axi_arprot:  in  std_logic_vector(2 downto 0);
    s0_axi_arvalid: in  std_logic;
    -- Read data channel
    s0_axi_rready:  in  std_logic;
    -- Write address channel
    s0_axi_awaddr:  in  std_logic_vector(11 downto 0);
    s0_axi_awprot:  in  std_logic_vector(2 downto 0);
    s0_axi_awvalid: in  std_logic;
    -- Write data channel
    s0_axi_wdata:   in  std_logic_vector(31 downto 0);
    s0_axi_wstrb:   in  std_logic_vector(3 downto 0);
    s0_axi_wvalid:  in  std_logic;
    -- Write response channel
    s0_axi_bready:  in  std_logic;
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    s0_axi_arready: out std_logic;
    -- Read data channel
    s0_axi_rdata:   out std_logic_vector(31 downto 0);
    s0_axi_rresp:   out std_logic_vector(1 downto 0);
    s0_axi_rvalid:  out std_logic;
    -- Write address channel
    s0_axi_awready: out std_logic;
    -- Write data channel
    s0_axi_wready:  out std_logic;
    -- Write response channel
    s0_axi_bvalid:  out std_logic;
    s0_axi_bresp:   out std_logic_vector(1 downto 0);

    ---------------------------
    -- AXI slave port s1_axi --
    ------------------------------
    -- Inputs (master to slave) --
    ------------------------------
    -- Read address channel
    s1_axi_arid:    in  std_logic_vector(5 downto 0);
    s1_axi_araddr:  in  std_logic_vector(29 downto 0);
    s1_axi_arlen:   in  std_logic_vector(3 downto 0);
    s1_axi_arsize:  in  std_logic_vector(2 downto 0);
    s1_axi_arburst: in  std_logic_vector(1 downto 0);
    s1_axi_arlock:  in  std_logic_vector(1 downto 0);
    s1_axi_arcache: in  std_logic_vector(3 downto 0);
    s1_axi_arprot:  in  std_logic_vector(2 downto 0);
    s1_axi_arqos:   in  std_logic_vector(3 downto 0);
    s1_axi_arvalid: in  std_logic;
    -- Read data channel
    s1_axi_rready:  in  std_logic;
    -- Write address channel
    s1_axi_awid:    in  std_logic_vector(5 downto 0);
    s1_axi_awaddr:  in  std_logic_vector(29 downto 0);
    s1_axi_awlen:   in  std_logic_vector(3 downto 0);
    s1_axi_awsize:  in  std_logic_vector(2 downto 0);
    s1_axi_awburst: in  std_logic_vector(1 downto 0);
    s1_axi_awlock:  in  std_logic_vector(1 downto 0);
    s1_axi_awcache: in  std_logic_vector(3 downto 0);
    s1_axi_awprot:  in  std_logic_vector(2 downto 0);
    s1_axi_awqos:   in  std_logic_vector(3 downto 0);
    s1_axi_awvalid: in  std_logic;
    -- Write data channel
    s1_axi_wid:     in  std_logic_vector(5 downto 0);
    s1_axi_wdata:   in  std_logic_vector(31 downto 0);
    s1_axi_wstrb:   in  std_logic_vector(3 downto 0);
    s1_axi_wlast:   in  std_logic;
    s1_axi_wvalid:  in  std_logic;
    -- Write response channel
    s1_axi_bready:  in  std_logic;
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    s1_axi_arready: out std_logic;
    -- Read data channel
    s1_axi_rid:     out std_logic_vector(5 downto 0);
    s1_axi_rdata:   out std_logic_vector(31 downto 0);
    s1_axi_rresp:   out std_logic_vector(1 downto 0);
    s1_axi_rlast:   out std_logic;
    s1_axi_rvalid:  out std_logic;
    -- Write address channel
    s1_axi_awready: out std_logic;
    -- Write data channel
    s1_axi_wready:  out std_logic;
    -- Write response channel
    s1_axi_bvalid:  out std_logic;
    s1_axi_bid:     out std_logic_vector(5 downto 0);
    s1_axi_bresp:   out std_logic_vector(1 downto 0);

    ---------------------------
    -- AXI master port m_axi --
    ---------------------------
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    m_axi_arid:    out std_logic_vector(5 downto 0);
    m_axi_araddr:  out std_logic_vector(31 downto 0);
    m_axi_arlen:   out std_logic_vector(3 downto 0);
    m_axi_arsize:  out std_logic_vector(2 downto 0);
    m_axi_arburst: out std_logic_vector(1 downto 0);
    m_axi_arlock:  out std_logic_vector(1 downto 0);
    m_axi_arcache: out std_logic_vector(3 downto 0);
    m_axi_arprot:  out std_logic_vector(2 downto 0);
    m_axi_arqos:   out std_logic_vector(3 downto 0);
    m_axi_arvalid: out std_logic;
    -- Read data channel
    m_axi_rready:  out std_logic;
    -- Write address channel
    m_axi_awid:    out std_logic_vector(5 downto 0);
    m_axi_awaddr:  out std_logic_vector(31 downto 0);
    m_axi_awlen:   out std_logic_vector(3 downto 0);
    m_axi_awsize:  out std_logic_vector(2 downto 0);
    m_axi_awburst: out std_logic_vector(1 downto 0);
    m_axi_awlock:  out std_logic_vector(1 downto 0);
    m_axi_awcache: out std_logic_vector(3 downto 0);
    m_axi_awprot:  out std_logic_vector(2 downto 0);
    m_axi_awqos:   out std_logic_vector(3 downto 0);
    m_axi_awvalid: out std_logic;
    -- Write data channel
    m_axi_wid:     out std_logic_vector(5 downto 0);
    m_axi_wdata:   out std_logic_vector(31 downto 0);
    m_axi_wstrb:   out std_logic_vector(3 downto 0);
    m_axi_wlast:   out std_logic;
    m_axi_wvalid:  out std_logic;
    -- Write response channel
    m_axi_bready:  out std_logic;
    ------------------------------
    -- Inputs (slave to master) --
    ------------------------------
    -- Read address channel
    m_axi_arready: in  std_logic;
    -- Read data channel
    m_axi_rid:     in  std_logic_vector(5 downto 0);
    m_axi_rdata:   in  std_logic_vector(31 downto 0);
    m_axi_rresp:   in  std_logic_vector(1 downto 0);
    m_axi_rlast:   in  std_logic;
    m_axi_rvalid:  in  std_logic;
    -- Write address channel
    m_axi_awready: in  std_logic;
    -- Write data channel
    m_axi_wready:  in  std_logic;
    -- Write response channel
    m_axi_bvalid:  in  std_logic;
    m_axi_bid:     in  std_logic_vector(5 downto 0);
    m_axi_bresp:   in  std_logic_vector(1 downto 0);

    -- GPIO
    gpi:        in  std_logic_vector(7 downto 0);
    gpo:        out std_logic_vector(7 downto 0)
  );
end entity axi_register_wrapper;

architecture rtl of axi_register_wrapper is

    signal s0_axi_m2s: axilite_gp_m2s;
    signal s0_axi_s2m: axilite_gp_s2m;
    signal s1_axi_m2s: axi_gp_m2s;
    signal s1_axi_s2m: axi_gp_s2m;
    signal m_axi_m2s: axi_gp_m2s;
    signal m_axi_s2m: axi_gp_s2m;
    signal gpi_local: std_ulogic_vector(7 downto 0);
    signal gpo_local: std_ulogic_vector(7 downto 0);

begin

  i_axi_register: entity work.axi_register
  port map(
    aclk       => aclk,
    aresetn    => aresetn,
    s0_axi_m2s => s0_axi_m2s,
    s0_axi_s2m => s0_axi_s2m,
    s1_axi_m2s => s1_axi_m2s,
    s1_axi_s2m => s1_axi_s2m,
    m_axi_m2s  => m_axi_m2s,
    m_axi_s2m  => m_axi_s2m,
    gpi        => gpi_local,
    gpo        => gpo_local
  );

  s0_axi_m2s.araddr  <= std_ulogic_vector(X"00000" & s0_axi_araddr);
  s0_axi_m2s.arprot  <= std_ulogic_vector(s0_axi_arprot);
  s0_axi_m2s.arvalid <= s0_axi_arvalid;

  s0_axi_m2s.rready  <= s0_axi_rready;

  s0_axi_m2s.awaddr  <= std_ulogic_vector(X"00000" & s0_axi_awaddr);
  s0_axi_m2s.awprot  <= std_ulogic_vector(s0_axi_awprot);
  s0_axi_m2s.awvalid <= s0_axi_awvalid;

  s0_axi_m2s.wdata   <= std_ulogic_vector(s0_axi_wdata);
  s0_axi_m2s.wstrb   <= std_ulogic_vector(s0_axi_wstrb);
  s0_axi_m2s.wvalid  <= s0_axi_wvalid;

  s0_axi_m2s.bready  <= s0_axi_bready;

  s0_axi_arready     <= s0_axi_s2m.arready;

  s0_axi_rdata       <= std_logic_vector(s0_axi_s2m.rdata);
  s0_axi_rresp       <= std_logic_vector(s0_axi_s2m.rresp);
  s0_axi_rvalid      <= s0_axi_s2m.rvalid;

  s0_axi_awready     <= s0_axi_s2m.awready;

  s0_axi_wready      <= s0_axi_s2m.wready;

  s0_axi_bvalid      <= s0_axi_s2m.bvalid;
  s0_axi_bresp       <= std_logic_vector(s0_axi_s2m.bresp);

  s1_axi_m2s.arid    <= std_ulogic_vector(s1_axi_arid);
  s1_axi_m2s.araddr  <= std_ulogic_vector("00" & s1_axi_araddr);
  s1_axi_m2s.arlen   <= std_ulogic_vector(s1_axi_arlen);
  s1_axi_m2s.arsize  <= std_ulogic_vector(s1_axi_arsize);
  s1_axi_m2s.arburst <= std_ulogic_vector(s1_axi_arburst);
  s1_axi_m2s.arlock  <= std_ulogic_vector(s1_axi_arlock);
  s1_axi_m2s.arcache <= std_ulogic_vector(s1_axi_arcache);
  s1_axi_m2s.arprot  <= std_ulogic_vector(s1_axi_arprot);
  s1_axi_m2s.arqos   <= std_ulogic_vector(s1_axi_arqos);
  s1_axi_m2s.arvalid <= s1_axi_arvalid;

  s1_axi_m2s.rready  <= s1_axi_rready;

  s1_axi_m2s.awid    <= std_ulogic_vector(s1_axi_awid);
  s1_axi_m2s.awaddr  <= std_ulogic_vector("00" & s1_axi_awaddr);
  s1_axi_m2s.awlen   <= std_ulogic_vector(s1_axi_awlen);
  s1_axi_m2s.awsize  <= std_ulogic_vector(s1_axi_awsize);
  s1_axi_m2s.awburst <= std_ulogic_vector(s1_axi_awburst);
  s1_axi_m2s.awlock  <= std_ulogic_vector(s1_axi_awlock);
  s1_axi_m2s.awcache <= std_ulogic_vector(s1_axi_awcache);
  s1_axi_m2s.awprot  <= std_ulogic_vector(s1_axi_awprot);
  s1_axi_m2s.awqos   <= std_ulogic_vector(s1_axi_awqos);
  s1_axi_m2s.awvalid <= s1_axi_awvalid;

  s1_axi_m2s.wid     <= std_ulogic_vector(s1_axi_wid);
  s1_axi_m2s.wdata   <= std_ulogic_vector(s1_axi_wdata);
  s1_axi_m2s.wstrb   <= std_ulogic_vector(s1_axi_wstrb);
  s1_axi_m2s.wlast   <= s1_axi_wlast;
  s1_axi_m2s.wvalid  <= s1_axi_wvalid;

  s1_axi_m2s.bready  <= s1_axi_bready;

  s1_axi_arready     <= s1_axi_s2m.arready;

  s1_axi_rid         <= std_logic_vector(s1_axi_s2m.rid);
  s1_axi_rdata       <= std_logic_vector(s1_axi_s2m.rdata);
  s1_axi_rresp       <= std_logic_vector(s1_axi_s2m.rresp);
  s1_axi_rlast       <= s1_axi_s2m.rlast;
  s1_axi_rvalid      <= s1_axi_s2m.rvalid;

  s1_axi_awready     <= s1_axi_s2m.awready;

  s1_axi_wready      <= s1_axi_s2m.wready;

  s1_axi_bvalid      <= s1_axi_s2m.bvalid;
  s1_axi_bid         <= std_logic_vector(s1_axi_s2m.bid);
  s1_axi_bresp       <= std_logic_vector(s1_axi_s2m.bresp);

  m_axi_arid         <= std_logic_vector(m_axi_m2s.arid);
  m_axi_araddr       <= std_logic_vector(m_axi_m2s.araddr);
  m_axi_arlen        <= std_logic_vector(m_axi_m2s.arlen);
  m_axi_arsize       <= std_logic_vector(m_axi_m2s.arsize);
  m_axi_arburst      <= std_logic_vector(m_axi_m2s.arburst);
  m_axi_arlock       <= std_logic_vector(m_axi_m2s.arlock);
  m_axi_arcache      <= std_logic_vector(m_axi_m2s.arcache);
  m_axi_arprot       <= std_logic_vector(m_axi_m2s.arprot);
  m_axi_arqos        <= std_logic_vector(m_axi_m2s.arqos);
  m_axi_arvalid      <= m_axi_m2s.arvalid;

  m_axi_rready       <= m_axi_m2s.rready;

  m_axi_awid         <= std_logic_vector(m_axi_m2s.awid);
  m_axi_awaddr       <= std_logic_vector(m_axi_m2s.awaddr);
  m_axi_awlen        <= std_logic_vector(m_axi_m2s.awlen);
  m_axi_awsize       <= std_logic_vector(m_axi_m2s.awsize);
  m_axi_awburst      <= std_logic_vector(m_axi_m2s.awburst);
  m_axi_awlock       <= std_logic_vector(m_axi_m2s.awlock);
  m_axi_awcache      <= std_logic_vector(m_axi_m2s.awcache);
  m_axi_awprot       <= std_logic_vector(m_axi_m2s.awprot);
  m_axi_awqos        <= std_logic_vector(m_axi_m2s.awqos);
  m_axi_awvalid      <= m_axi_m2s.awvalid;

  m_axi_wid          <= std_logic_vector(m_axi_m2s.wid);
  m_axi_wdata        <= std_logic_vector(m_axi_m2s.wdata);
  m_axi_wstrb        <= std_logic_vector(m_axi_m2s.wstrb);
  m_axi_wlast        <= m_axi_m2s.wlast;
  m_axi_wvalid       <= m_axi_m2s.wvalid;

  m_axi_bready       <= m_axi_m2s.bready;

  m_axi_s2m.arready  <= m_axi_arready;

  m_axi_s2m.rid      <= std_ulogic_vector(m_axi_rid);
  m_axi_s2m.rdata    <= std_ulogic_vector(m_axi_rdata);
  m_axi_s2m.rresp    <= std_ulogic_vector(m_axi_rresp);
  m_axi_s2m.rlast    <= m_axi_rlast;
  m_axi_s2m.rvalid   <= m_axi_rvalid;

  m_axi_s2m.awready  <= m_axi_awready;

  m_axi_s2m.wready   <= m_axi_wready;

  m_axi_s2m.bvalid   <= m_axi_bvalid;
  m_axi_s2m.bid      <= std_ulogic_vector(m_axi_bid);
  m_axi_s2m.bresp    <= std_ulogic_vector(m_axi_bresp);

  gpi_local         <= std_ulogic_vector(gpi);
  gpo               <= std_logic_vector(gpo_local);

end architecture rtl;
