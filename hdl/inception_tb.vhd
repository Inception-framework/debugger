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
    clk_original   : out std_logic;      
    slcs 	   : out std_logic;                               ---output chip select
    fdata          : inout std_logic_vector(31 downto 0);         
    faddr          : out std_logic_vector(1 downto 0);            ---output fifo address
    slrd	   : out std_logic;                               ---output read select
    sloe	   : out std_logic;                               ---output output enable select
    slwr	   : out std_logic;                               ---output write select
        
    flaga	   : in std_logic;                                
    flagb	   : in std_logic;
    flagc	   : in std_logic;
    flagd	   : in std_logic;

    pktend	   : out std_logic;                               ---output pkt end 
    mode_p    : in std_logic_vector(2 downto 0)
    
  );
  end component;
  
    signal aclk:        std_logic;  -- Clock
    signal aresetn:     std_logic;  -- Synchronous, active low, reset
    
    signal btn_re:          std_logic;  -- Command button
    signal sw:              std_logic_vector(3 downto 0); -- Slide switches
    signal led:             std_logic_vector(3 downto 0); -- LEDs
    signal jtag_state_led:  std_logic_vector(3 downto 0);
    signal r:               std_ulogic_vector(31 downto 0);
    signal status:          std_ulogic_vector(31 downto 0);
    
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
    signal clk_original   :  std_logic;      
    signal slcs 	   :  std_logic;                               ---output chip select
    signal fdata          :  std_logic_vector(31 downto 0);         
    signal faddr          :  std_logic_vector(1 downto 0);            ---output fifo address
    signal slrd	   :  std_logic;                               ---output read select
    signal sloe	   :  std_logic;                               ---output output enable select
    signal slwr	   :  std_logic;                               ---output write select
        
    signal flaga	   :  std_logic;                                
    signal flagb	   :  std_logic;
    signal flagc	   :  std_logic;
    signal flagd	   :  std_logic;

    signal pktend	   :  std_logic;                               ---output pkt end 
    signal mode_p    :  std_logic_vector(2 downto 0); 

 begin
  
 mode_p <= "101"; --loopback
 period <= 3; -- small value for simulation, for real code chose 15 so that jtag freq ~3MHz
 dut: inception 
  port map(
    aclk => aclk,
    aresetn => aresetn,
    
    btn_re => btn_re,
    sw => sw,
    led => led,
    jtag_state_led => jtag_state_led,
    r => r,
    status => status,
    
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
    clk_original => clk_original,  
    slcs 	  => slcs,
    fdata   => fdata,       
    faddr   => faddr,
    slrd	   => slrd,
    sloe	   => sloe,
    slwr	   => slwr,
        
    flaga	  => flaga,                               
    flagb	  => flagb, 
    flagc	  => flagc, 
    flagd	  => flagd,

    pktend	 => pktend,                             
    mode_p  => mode_p  
    
  );
 
 aresetn <= '0', '1' after 15 ns;
 clk_proc: process
 begin
   aclk <= '1';
   wait for 5 ns;
   aclk <= '0';
   wait for 5 ns;
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
    variable loop_back_data: std_logic :='0';
  begin
    if(TCK'event and TCK='0')then
      TDO <= loop_back_data;
      loop_back_data := not loop_back_data;
    end if;
  end process;
  
end architecture beh;


