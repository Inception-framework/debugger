--
-- Copyright (C) Telecom ParisTech
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
--

-- See the README.md file for a detailed description of SAB4Z

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;

entity sab4z is
  port(
    aclk:       in std_logic;  -- Clock
    aresetn:    in std_logic;  -- Synchronous, active low, reset
    btn:        in std_logic;  -- Command button
    btn_re:     in std_logic;  -- Rising edge of command button
    sw:         in  std_logic_vector(3 downto 0); -- Slide switches
    led:        out std_logic_vector(3 downto 0); -- LEDs

    --------------------------------
    -- AXI lite slave port s0_axi --
    --------------------------------
    -- Inputs (master to slave) --
    ------------------------------
    -- Read address channel
    s0_axi_araddr:  in  std_logic_vector(29 downto 0);
    s0_axi_arprot:  in  std_logic_vector(2 downto 0);
    s0_axi_arvalid: in  std_logic;
    -- Read data channel
    s0_axi_rready:  in  std_logic;
    -- Write address channel
    s0_axi_awaddr:  in  std_logic_vector(29 downto 0);
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
    s0_axi_bresp:   out std_logic_vector(1 downto 0);
    s0_axi_bvalid:  out std_logic;

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
    s1_axi_bid:     out std_logic_vector(5 downto 0);
    s1_axi_bresp:   out std_logic_vector(1 downto 0);
    s1_axi_bvalid:  out std_logic;

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
    m_axi_bid:     in  std_logic_vector(5 downto 0);
    m_axi_bresp:   in  std_logic_vector(1 downto 0);
    m_axi_bvalid:  in  std_logic
  );
end entity sab4z;

architecture rtl of sab4z is

  -- Record versions of AXI signals
  signal s0_axi_m2s: axilite_gp_m2s;
  signal s0_axi_s2m: axilite_gp_s2m;
  signal s1_axi_m2s: axi_gp_m2s;
  signal s1_axi_s2m: axi_gp_s2m;
  signal m_axi_m2s: axi_gp_m2s;
  signal m_axi_s2m: axi_gp_s2m;

  -- STATUS register
  signal status: std_ulogic_vector(31 downto 0);

  alias life:    std_ulogic_vector(3 downto 0) is status(3 downto 0);
  alias cnt:     std_ulogic_vector(3 downto 0) is status(7 downto 4);
  alias arcnt:   std_ulogic_vector(3 downto 0) is status(11 downto 8);
  alias rcnt:    std_ulogic_vector(3 downto 0) is status(15 downto 12);
  alias awcnt:   std_ulogic_vector(3 downto 0) is status(19 downto 16);
  alias wcnt:    std_ulogic_vector(3 downto 0) is status(23 downto 20);
  alias bcnt:    std_ulogic_vector(3 downto 0) is status(27 downto 24);

  -- R register
  signal r: std_ulogic_vector(31 downto 0);

  -- Or reduction of std_ulogic_vector
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

begin

  -- LED outputs
  process(status, r, btn)
    variable m0: std_ulogic_vector(63 downto 0);
    variable m1: std_ulogic_vector(31 downto 0);
    variable m2: std_ulogic_vector(15 downto 0);
    variable m3: std_ulogic_vector(7 downto 0);
    variable m4: std_ulogic_vector(3 downto 0);
  begin
    m0 := r & status;
    if cnt(3) = '1' then
      m1 := m0(63 downto 32);
    else
      m1 := m0(31 downto 0);
    end if;
    if cnt(2) = '1' then
      m2 := m1(31 downto 16);
    else
      m2 := m1(15 downto 0);
    end if;
    if cnt(1) = '1' then
      m3 := m2(15 downto 8);
    else
      m3 := m2(7 downto 0);
    end if;
    if cnt(0) = '1' then
      m4 := m3(7 downto 4);
    else
      m4 := m3(3 downto 0);
    end if;
    if btn = '1' then
      m4 := cnt;
    end if;
    led <= std_logic_vector(m4);
  end process;

  -- Status register
  process(aclk)
    constant lifecntwidth: positive := 25;
    variable lifecnt: unsigned(lifecntwidth - 1 downto 0); -- Life monitor counter
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        status <= (0 => '1', others => '0');
        lifecnt := (others => '0');
      else
        -- Life monitor
        lifecnt := lifecnt + 1;
        if lifecnt(lifecntwidth - 1) = '1' then
          lifecnt(lifecntwidth - 1) := '0';
          life <= life(2 downto 0) & life(3);
        end if;
        -- BTN event counter
        if btn_re = '1' then
          cnt <= std_ulogic_vector(unsigned(cnt) + 1);
        end if;
        -- S1_AXI address read transactions counter
        if s1_axi_m2s.arvalid = '1' and s1_axi_s2m.arready = '1' then
          arcnt <= std_ulogic_vector(unsigned(arcnt) + 1);
        end if;
        -- S1_AXI data read transactions counter
        if s1_axi_s2m.rvalid = '1' and s1_axi_m2s.rready = '1' then
          rcnt <= std_ulogic_vector(unsigned(rcnt) + 1);
        end if;
        -- S1_AXI address write transactions counter
        if s1_axi_m2s.awvalid = '1' and s1_axi_s2m.awready = '1' then
          awcnt <= std_ulogic_vector(unsigned(awcnt) + 1);
        end if;
        -- S1_AXI data write transactions counter
        if s1_axi_m2s.wvalid = '1' and s1_axi_s2m.wready = '1' then
          wcnt <= std_ulogic_vector(unsigned(wcnt) + 1);
        end if;
        -- S1_AXI write response transactions counter
        if s1_axi_s2m.bvalid = '1' and s1_axi_m2s.bready = '1' then
          bcnt <= std_ulogic_vector(unsigned(bcnt) + 1);
        end if;
        -- Slide switches
        status(31 downto 28) <= std_ulogic_vector(sw);
      end if;
    end if;
  end process;

  -- Forwarding of S1_AXI read-write requests to M_AXI and of M_AXI responses to S1_AXI
  s1_axi_to_m_axi: process(s1_axi_m2s, m_axi_s2m)
  begin
    m_axi_m2s <= s1_axi_m2s;
    m_axi_m2s.araddr(31 downto 30) <= "00";
    m_axi_m2s.awaddr(31 downto 30) <= "00";
    s1_axi_s2m <= m_axi_s2m; 
  end process s1_axi_to_m_axi;

  -- S0_AXI read-write requests
  s0_axi_pr: process(aclk)
    -- idle: waiting for AXI master requests: when receiving write address and data valid (higher priority than read), perform the write, assert write address
    --       ready, write data ready and bvalid, go to w1, else, when receiving address read valid, perform the read, assert read address ready, read data valid
    --       and go to r1
    -- w1:   deassert write address ready and write data ready, wait for write response ready: when receiving it, deassert write response valid, go to idle
    -- r1:   deassert read address ready, wait for read response ready: when receiving it, deassert read data valid, go to idle
    type state_type is (idle, w1, r1);
    variable state: state_type;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        s0_axi_s2m <= (rdata => (others => '0'), rresp => axi_resp_okay, bresp => axi_resp_okay, others => '0');
        state := idle;
      else
        -- s0_axi write and read
        case state is
          when idle =>
            if s0_axi_m2s.awvalid = '1' and s0_axi_m2s.wvalid = '1' then -- Write address and data
              if or_reduce(s0_axi_m2s.awaddr(31 downto 3)) /= '0' then -- If unmapped address
                s0_axi_s2m.bresp <= axi_resp_decerr;
              elsif s0_axi_m2s.awaddr(2) = '0' then -- If read-only status register
                s0_axi_s2m.bresp <= axi_resp_slverr;
              else
                s0_axi_s2m.bresp <= axi_resp_okay;
                for i in 0 to 3 loop
                  if s0_axi_m2s.wstrb(i) = '1' then
                    r(8 * i + 7 downto 8 * i) <= s0_axi_m2s.wdata(8 * i + 7 downto 8 * i);
                  end if;
                end loop;
              end if;
              s0_axi_s2m.awready <= '1';
              s0_axi_s2m.wready <= '1';
              s0_axi_s2m.bvalid <= '1';
              state := w1;
            elsif s0_axi_m2s.arvalid = '1' then
              if or_reduce(s0_axi_m2s.araddr(31 downto 3)) /= '0' then -- If unmapped address
                s0_axi_s2m.rdata <= (others => '0');
                s0_axi_s2m.rresp <= axi_resp_decerr;
              else
                s0_axi_s2m.rresp <= axi_resp_okay;
                if s0_axi_m2s.araddr(2) = '0' then -- If status register
                  s0_axi_s2m.rdata <= status;
                else
                  s0_axi_s2m.rdata <= r;
                end if;
              end if;
              s0_axi_s2m.arready <= '1';
              s0_axi_s2m.rvalid <= '1';
              state := r1;
            end if;
          when w1 =>
            s0_axi_s2m.awready <= '0';
            s0_axi_s2m.wready <= '0';
            if s0_axi_m2s.bready = '1' then
              s0_axi_s2m.bvalid <= '0';
              state := idle;
            end if;
          when r1 =>
            s0_axi_s2m.arready <= '0';
            if s0_axi_m2s.rready = '1' then
              s0_axi_s2m.rvalid <= '0';
              state := idle;
            end if;
        end case;
      end if;
    end if;
  end process s0_axi_pr;

  -- Record types to flat signals
  s0_axi_m2s.araddr  <= std_ulogic_vector("00" & s0_axi_araddr);
  s0_axi_m2s.arprot  <= std_ulogic_vector(s0_axi_arprot);
  s0_axi_m2s.arvalid <= s0_axi_arvalid;

  s0_axi_m2s.rready  <= s0_axi_rready;

  s0_axi_m2s.awaddr  <= std_ulogic_vector("00" & s0_axi_awaddr);
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

end architecture rtl;
