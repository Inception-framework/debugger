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

USE std.textio.all;
use ieee.std_logic_textio.all; 

entity inception_tb is
end entity inception_tb;



architecture beh of inception_tb is
  
  component inception is
  port(
    aclk:       in std_logic;  -- Clock
    aresetn:    in std_logic;  -- Synchronous, active low, reset
    
    btn1_re,btn2_re:in std_logic;  -- Command button
    sw:             in  std_logic_vector(3 downto 0); -- Slide switches
    led:            out std_logic_vector(3 downto 0); -- LEDs
    jtag_state_led: out std_logic_vector(3 downto 0);
    r:              in std_ulogic_vector(31 downto 0);
    status:         out std_ulogic_vector(31 downto 0);
    
    irq: in std_logic;
    irq_ack: out std_logic;
    ----------------------
    -- jtag ctrl master --
    ----------------------
    period          : in  natural range 1 to 31;
    TDO		    : in  STD_LOGIC;
    TCK		    : out  STD_LOGIC;
    TMS		    : out  STD_LOGIC;
    TDI		    : out  STD_LOGIC;
    TRST            : out  STD_LOGIC;

    -----------------------
    -- slave fifo master --
    -----------------------
    clk_out	   : out std_logic;                               ---output clk 100 Mhz and 180 phase shift 
    fdata          : inout std_logic_vector(31 downto 0);         
    sloe	   : out std_logic;                               ---output output enable select
    slop	   : out std_logic;                               ---output write select
        
    slwr_rdy	   : in std_logic;                                
    slrd_rdy	   : in std_logic

  );
  end component;

  component fifo_ram is
  generic(
    width: natural := 32;
    addr_size: natural := 10
  );
  port(
    aclk:  in  std_logic;
    aresetn: in std_logic;
    empty: out std_logic;
    full:  out std_logic;
    put:   in  std_logic;
    get:   in  std_logic;
    din:   in  std_logic_vector(width-1 downto 0);
    dout:  out std_logic_vector(width-1 downto 0)
  );
  end component;
 
    signal aclk:        std_logic;  -- Clock
    signal aresetn:     std_logic;  -- Synchronous, active low, reset
    
    signal btn1_re,btn2_re:          std_logic;  -- Command button
    signal sw:              std_logic_vector(3 downto 0); -- Slide switches
    signal led:             std_logic_vector(3 downto 0); -- LEDs
    signal jtag_state_led:  std_logic_vector(3 downto 0);
    signal r:               std_ulogic_vector(31 downto 0);
    signal status:          std_ulogic_vector(31 downto 0);
    
    signal irq, irq_ack:    std_logic;
    ----------------------
    -- jtag ctrl master --
    ----------------------
    signal period           :   natural range 1 to 31;
    signal TDO		    :   STD_LOGIC;
    signal TCK		    :   STD_LOGIC;
    signal TMS		    :   STD_LOGIC;
    signal TDI		    :   STD_LOGIC;
    signal TRST            :   STD_LOGIC;

    -----------------------
    -- slave fifo master --
    -----------------------
    signal clk_out	   :  std_logic;                               ---output clk 100 Mhz and 180 phase shift 
    signal fdata          :  std_logic_vector(31 downto 0);         
    signal sloe	   :  std_logic;                               ---output output enable select
    signal slop	   :  std_logic;                               ---output write select
        
    signal slwr_rdy	   :  std_logic;                                
    signal slrd_rdy	   :  std_logic;

    type fx3_state_t is (reset,idle,read,write);
    signal fx3_state: fx3_state_t;
    signal slop_d,sloe_d: std_logic;

    signal snd_get,snd_put,snd_empty,snd_full : std_logic;
    signal rcv_get,rcv_put,rcv_empty,rcv_full : std_logic;
    signal snd_din,snd_dout,rcv_din,rcv_dout  : std_logic_vector(31 downto 0);
 begin
  
 period <= 3; -- small value for simulation, for real code chose 15 so that jtag freq ~3MHz
 dut: inception 
  port map(
    aclk => aclk,
    aresetn => aresetn,
    
    btn1_re => btn1_re,
    btn2_re => btn2_re,
    sw => sw,
    led => led,
    jtag_state_led => jtag_state_led,
    r => r,
    status => status,
    
    irq => irq,
    irq_ack => irq_ack,
    ----------------------
    -- jtag ctrl master --
    ----------------------
    period        => period,
    TDO		  => TDO,
    TCK		  => TCK, 
    TMS		  => TMS,
    TDI		  => TDI,
    TRST   => TRST,    

    -----------------------
    -- slave fifo master --
    -----------------------
    clk_out	=> clk_out,  
    fdata   => fdata,       
    sloe	   => sloe,
    slop	   => slop,
    slwr_rdy       => slwr_rdy,
    slrd_rdy       => slrd_rdy
    
  );
 
 aresetn <= '0', '1' after 15 ns;
 clk_proc: process
 begin
   aclk <= '1';
   wait for 5 ns;
   aclk <= '0';
   wait for 5 ns;
 end process;

 irq_gen_proc: process
 begin
   irq_loop: for i in 0 to 2 loop
     irq <= '0';
     wait for 457*10 ns;
     irq <= '1';
     wait until irq_ack = '1';
   end loop irq_loop;
   wait;
 end process;

 o_proc: process(TCK)

    file output_fp: text open write_mode is "../../io/output.txt";
    variable output_line: line;
    variable output_data: std_logic_vector(1 downto 0);
  begin
 
    if(TCK'event and TCK='1')then
      output_data := TMS&TDI;
      write(output_line,output_data);
      writeline(output_fp,output_line);
    end if;

  end process;

  jtag_slave_stub_proc: process(TCK)
    variable loop_back_data: std_logic;
  begin
    if(TCK'event and TCK='1')then
      loop_back_data := TDI;
    elsif(TCK'event and TCK='0')then
      TDO <= loop_back_data;
    end if;
  end process;
  
  ----------------------------
  -- simulate the fx3 gpif2 --
  ----------------------------
  input_flop_proc: process(clk_out)
  begin
    if(clk_out'event and clk_out='1')then
      if(aresetn='0')then
        slop_d <= '0';
	sloe_d <= '0';
      else
        slop_d <= slop;
	sloe_d <= sloe;
      end if;
    end if;
  end process input_flop_proc;

  data_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        snd_get <= '0';
      elsif(slop='1' and sloe='1')then
        snd_get <= '1';
      else
        snd_get <= '0';
      end if;
    end if;
  end process data_proc;

  fdata <= snd_dout when sloe='1' else (others=>'Z');

  rcv_din <= fdata;
  rcv_put <= '1' when (slop='1' and sloe='0') else '0';

  slrd_rdy <= not snd_empty;
  slwr_rdy <= not rcv_full;

  fx3_proc: process(clk_out)
  begin
    if(clk_out'event and clk_out='1')then
      if(aresetn='0')then
        fx3_state <= reset;
      else
        case fx3_state is
	  when reset =>
	    fx3_state <= idle;
	  when idle =>
	    if(slop_d='1')then
	      if(sloe_d='1')then
	        fx3_state <= read;
	      else
	        fx3_state <= write;
	      end if;
	    end if;
	  when read =>
	    if(slop_d='0' or sloe_d='0')then
	      fx3_state <= idle;
	    end if;
	  when write =>
	    if(slop_d='0' and sloe_d='0')then
	      fx3_state <= idle;
	    end if;
	end case;
      end if;
    end if;
  end process fx3_proc;
--------------------------------------------------------
  -- local fifo to store commands reveived from the host --
  --------------------------------------------------------
  snd_fifo_inst : fifo_ram
    generic map(
      width => 32,
      addr_size => 4
    )
    port map(
      aclk => aclk,
      aresetn => aresetn,
      empty => snd_empty,
      full => snd_full,
      put => snd_put,
      get => snd_get,
      din => snd_din,
      dout => snd_dout
    );

  -------------------------------------------------------------
  -- local fifo to store data received from the fpga --
  -------------------------------------------------------------
  rcv_fifo_inst: fifo_ram
    generic map(
      width => 32,
      addr_size => 4
    )
    port map(
      aclk     => aclk,
      aresetn  => aresetn,
      empty    => rcv_empty,
      full     => rcv_full,
      put      => rcv_put,
      get      => rcv_get,
      din      => rcv_din,
      dout     => rcv_dout
    );
  
  --------------------------------------------------
  -- simulate host by taking commands from a file --
  --------------------------------------------------
  stub_input_proc: process
      file input_fp: text open read_mode is "../../io/input.txt";
      variable input_line : line;
      variable input_data : std_logic_vector(31 downto 0);
    begin
        snd_gen_loop: while(endfile(input_fp) = false) loop
        snd_put <= '0';
        wait for 15 ns;
        if(snd_full='1')then
          wait until snd_full='0';
	  wait for 5 ns;
        end if;
        readline(input_fp,input_line);
        hread(input_line,input_data);
        snd_put <= '1';
        snd_din <= input_data;
        wait for 10 ns;
      end loop snd_gen_loop;
      snd_put <='0';
      wait;
    end process;

end architecture beh;


