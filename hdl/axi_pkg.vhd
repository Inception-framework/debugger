--
-- Copyright (C) Telecom ParisTech
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
--

library ieee;
use ieee.std_logic_1164.all;

package axi_pkg is

  ------------------------------------------------
  -- Bit-widths of AXI fields as seen by the PL --
  ------------------------------------------------

  -- Common to all AXI interfaces
  constant axi_l: positive := 4;  -- len bit width
  constant axi_b: positive := 2;  -- burst bit width
  constant axi_a: positive := 32; -- address bit width
  constant axi_o: positive := 2;  -- lock bit width
  constant axi_p: positive := 3;  -- prot bit width
  constant axi_c: positive := 4;  -- cache bit width
  constant axi_r: positive := 2;  -- resp bit width
  constant axi_q: positive := 4;  -- qos bit width
  constant axi_s: positive := 3;  -- size bit width

  -- AXI_GP{0,1} AXI_HP{0:3} (when configured in 32 bits) ports (PL master to PS slave)
  constant axi_gp_i: positive := 6;  -- id  bit width
  constant axi_gp_m: positive := 4;  -- strb bit width
  constant axi_gp_d: positive := 8 * axi_gp_m; -- data bit width

  -- S_AXI_ACP ports (PL master to PS slave)
  constant axi_acp_i: positive := 3;  -- id  bit width
  constant axi_acp_u: positive := 5;  -- user bit width
  constant axi_acp_m: positive := 8;  -- strb bit width
  constant axi_acp_d: positive := 8 * axi_acp_m; -- data bit width

  constant axi_resp_okay:   std_ulogic_vector(axi_r - 1 downto 0) := "00";
  constant axi_resp_exokay: std_ulogic_vector(axi_r - 1 downto 0) := "01";
  constant axi_resp_slverr: std_ulogic_vector(axi_r - 1 downto 0) := "10";
  constant axi_resp_decerr: std_ulogic_vector(axi_r - 1 downto 0) := "11";

  constant axi_burst_fixed: std_ulogic_vector(axi_b - 1 downto 0) := "00";
  constant axi_burst_incr:  std_ulogic_vector(axi_b - 1 downto 0) := "01";
  constant axi_burst_wrap:  std_ulogic_vector(axi_b - 1 downto 0) := "10";
  constant axi_burst_res:   std_ulogic_vector(axi_b - 1 downto 0) := "11";

  -----------------------------------------------------------
  -- AXI ports. M2S: Master to slave. S2M: Slave to master --
  -----------------------------------------------------------

  -- AXI_GP ports
  type axi_gp_m2s is record
    -- Read address channel
    arid:    std_ulogic_vector(axi_gp_i - 1 downto 0);
    araddr:  std_ulogic_vector(axi_a - 1 downto 0);
    arlen:   std_ulogic_vector(axi_l - 1 downto 0);
    arsize:  std_ulogic_vector(axi_s - 1 downto 0);
    arburst: std_ulogic_vector(axi_b - 1 downto 0);
    arlock:  std_ulogic_vector(axi_o - 1 downto 0);
    arcache: std_ulogic_vector(axi_c - 1 downto 0);
    arprot:  std_ulogic_vector(axi_p - 1 downto 0);
    arqos:   std_ulogic_vector(axi_q - 1 downto 0);
    arvalid: std_ulogic;
    -- Read data channel
    rready:  std_ulogic;
    -- Write address channel
    awid:    std_ulogic_vector(axi_gp_i - 1 downto 0);
    awaddr:  std_ulogic_vector(axi_a - 1 downto 0);
    awlen:   std_ulogic_vector(axi_l - 1 downto 0);
    awsize:  std_ulogic_vector(axi_s - 1 downto 0);
    awburst: std_ulogic_vector(axi_b - 1 downto 0);
    awlock:  std_ulogic_vector(axi_o - 1 downto 0);
    awcache: std_ulogic_vector(axi_c - 1 downto 0);
    awprot:  std_ulogic_vector(axi_p - 1 downto 0);
    awqos:   std_ulogic_vector(axi_q - 1 downto 0);
    awvalid: std_ulogic;
    -- Write data channel
    wid:     std_ulogic_vector(axi_gp_i - 1 downto 0);
    wdata:   std_ulogic_vector(axi_gp_d - 1 downto 0);
    wstrb:   std_ulogic_vector(axi_gp_m - 1 downto 0);
    wlast:   std_ulogic;
    wvalid:  std_ulogic;
    -- Write response channel
    bready:  std_ulogic;
  end record;

  type axi_gp_s2m is record
    -- Read address channel
    arready: std_ulogic;
    -- Read data channel
    rid:     std_ulogic_vector(axi_gp_i - 1 downto 0);
    rdata:   std_ulogic_vector(axi_gp_d - 1 downto 0);
    rresp:   std_ulogic_vector(axi_r - 1 downto 0);
    rlast:   std_ulogic;
    rvalid:  std_ulogic;
    -- Write address channel
    awready: std_ulogic;
    -- Write data channel
    wready:  std_ulogic;
    -- Write response channel
    bid:     std_ulogic_vector(axi_gp_i - 1 downto 0);
    bvalid:  std_ulogic;
    bresp:   std_ulogic_vector(axi_r - 1 downto 0);
  end record;

  -- AXI_GP ports
  type axilite_gp_m2s is record
    -- Read address channel
    araddr:  std_ulogic_vector(axi_a - 1 downto 0);
    arprot:  std_ulogic_vector(axi_p - 1 downto 0);
    arvalid: std_ulogic;
    -- Read data channel
    rready:  std_ulogic;
    -- Write address channel
    awaddr:  std_ulogic_vector(axi_a - 1 downto 0);
    awprot:  std_ulogic_vector(axi_p - 1 downto 0);
    awvalid: std_ulogic;
    -- Write data channel
    wdata:   std_ulogic_vector(axi_gp_d - 1 downto 0);
    wstrb:   std_ulogic_vector(axi_gp_m - 1 downto 0);
    wvalid:  std_ulogic;
    -- Write response channel
    bready:  std_ulogic;
  end record;

  type axilite_gp_s2m is record
    -- Read address channel
    arready: std_ulogic;
    -- Read data channel
    rdata:   std_ulogic_vector(axi_gp_d - 1 downto 0);
    rresp:   std_ulogic_vector(axi_r - 1 downto 0);
    rvalid:  std_ulogic;
    -- Write address channel
    awready: std_ulogic;
    -- Write data channel
    wready:  std_ulogic;
    -- Write response channel
    bvalid:  std_ulogic;
    bresp:   std_ulogic_vector(axi_r - 1 downto 0);
  end record;

end package axi_pkg;
