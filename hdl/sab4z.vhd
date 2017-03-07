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
    s0_axi_bvalid:  out std_logic
  );
end entity sab4z;

architecture rtl of sab4z is

  -- Record versions of AXI signals
  signal s0_axi_m2s: axilite_gp_m2s;
  signal s0_axi_s2m: axilite_gp_s2m;

  -- STATUS register
  signal status: std_ulogic_vector(31 downto 0);

  alias life:    std_ulogic_vector(3 downto 0) is status(3 downto 0);
  alias cnt:     std_ulogic_vector(3 downto 0) is status(7 downto 4);
  alias arcnt:   std_ulogic_vector(3 downto 0) is status(11 downto 8);
  alias rcnt:    std_ulogic_vector(3 downto 0) is status(15 downto 12);
  alias awcnt:   std_ulogic_vector(3 downto 0) is status(19 downto 16);
  alias wcnt:    std_ulogic_vector(3 downto 0) is status(23 downto 20);
  alias bcnt:    std_ulogic_vector(3 downto 0) is status(27 downto 24);
  alias slsw:    std_ulogic_vector(3 downto 0) is status(31 downto 28);

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

  signal btn_sd: std_logic;  -- Synchronized and debounced command button
  signal btn_re: std_logic;  -- Rising edge of command button

begin

  -- Synchronizer - debouncer
  sd: entity work.debouncer(rtl)
    port map(clk   => aclk,
             srstn => aresetn,
             d     => btn,
             q     => btn_sd,
             r     => btn_re,
             f     => open,
             a     => open);

  -- LED outputs
  process(status, r, btn_sd)
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
    if btn_sd = '1' then
      m4 := cnt;
    end if;
    led <= std_logic_vector(m4);
  end process;

  -- Status register
  process(aclk)
    constant lifecntwidth: positive := 25;
    variable lifecnt: unsigned(lifecntwidth - 1 downto 0); -- Life monitor counter
    variable lifeleft2right: boolean;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        life  <= X"1";
        cnt   <= X"0";
        arcnt <= X"0";
        rcnt  <= X"0";
        awcnt <= X"0";
        wcnt  <= X"0";
        bcnt  <= X"0";
        lifecnt := (others => '0');
        lifeleft2right := true;
      else
        -- Life monitor
        lifecnt := lifecnt + 1;
        if lifecnt(lifecntwidth - 1) = '1' then
          lifecnt(lifecntwidth - 1) := '0';
          if lifeleft2right then
            life <= life(0) & life(3 downto 1);
            if life(1) = '1' then
              lifeleft2right := not lifeleft2right;
            end if;
          else
            life <= life(2 downto 0) & life(3);
            if life(2) = '1' then
              lifeleft2right := not lifeleft2right;
            end if;
          end if;
        end if;
        -- BTN event counter
        if btn_re = '1' then
          cnt <= std_ulogic_vector(unsigned(cnt) + 1);
        end if;
        -- Slide switches
        slsw <= std_ulogic_vector(sw);
      end if;
    end if;
  end process;

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

end architecture rtl;
