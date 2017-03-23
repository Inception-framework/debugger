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

use work.inception_pkg.all;

USE std.textio.all;
use ieee.std_logic_textio.all; 

entity inception is
  port(
    aclk:       in std_logic;  -- Clock
    aresetn:    in std_logic;  -- Synchronous, active low, reset
    
    btn_re:         in std_logic;  -- Command button
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
end entity inception;

architecture beh of inception is
  
  -- Jtag ctrl signals
  signal jtag_bit_count:     std_logic_vector(15 downto 0);
  signal jtag_shift_strobe:  std_logic;
  signal jtag_busy:          std_logic;
  signal jtag_state_start:   std_logic_vector(3 downto 0);
  signal jtag_state_end:     std_logic_vector(3 downto 0);
  signal jtag_state_current: std_logic_vector(3 downto 0);
  signal jtag_di:       std_logic_vector(31 downto 0);
  signal jtag_do:       std_logic_vector(31 downto 0);

  component ODDR2                       
  port(   
          D0	: in std_logic;              
          D1	: in std_logic;
          C0	: in std_logic;
          C1	: in std_logic;
          Q 	: out std_logic;
          CE      : in std_logic;
          S       : in std_logic; 
          R 	: in std_logic
    );     
  end component;

  component JTAG_Ctrl_Master is
    Generic (
      Addrbreite  : natural := 10;  -- Speicherlänge = 2^Addrbreite
      Wortbreite  : natural := 8
    );
    Port (
      CLK			: in  STD_LOGIC;
      aresetn                   : in  STD_LOGIC;
      -- JTAG Part
      period          : in  natural range 1 to 31;
      BitCount			: in  STD_LOGIC_VECTOR (15 downto 0);
      Shift_Strobe		: in  STD_LOGIC;								-- eins aktiv...
      TDO		        : in  STD_LOGIC;
      TCK		        : out  STD_LOGIC;
      TMS		        : out  STD_LOGIC;
      TDI		        : out  STD_LOGIC;
      TRst		        : out  STD_LOGIC;
      Busy		        : out  STD_LOGIC;
      StateStart		: in	 std_logic_vector(3 downto 0);
      StateEnd			: in	 std_logic_vector(3 downto 0);
      StateCurrent		: out	 std_logic_vector(3 downto 0);
      -- Ram Part
      Din		        : in  STD_LOGIC_VECTOR (31 downto 0);
      Dout			: out STD_LOGIC_VECTOR (31 downto 0)
  );
  end component;
  
  component slaveFIFO2b_fpga_top is
  port(
    aresetn : in std_logic;                                ---input reset active low
    aclk    : in std_logic;
    slcs 	  : out std_logic;                               ---output chip select
    fdata   : inout std_logic_vector(31 downto 0);         
    faddr   : out std_logic_vector(1 downto 0);            ---output fifo address
    slrd	   : out std_logic;                               ---output read select
    sloe	   : out std_logic;                               ---output output enable select
    slwr	   : out std_logic;                               ---output write select
                    
    flaga	   : in std_logic;                                
    flagb	   : in std_logic;
    flagc	   : in std_logic;
    flagd	   : in std_logic;


    pktend	   : out std_logic;                               ---output pkt end 
    mode_p     : in std_logic_vector(2 downto 0)              ----signals for debugging
  );
  end component slaveFIFO2b_fpga_top;
 
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

 
 
  type jtag_st_t is (idle,read_cmd,read_addr,run_cmd,wait_cmd,done);
  type jtag_op_t is (read,write,reset);
  type jtag_state_t is record
    st: jtag_st_t;
    op: jtag_op_t;
    step:   natural range 0 to NSTEPS-1;
    size:   natural range 1 to 4;
    number: natural range 0 to 2**24-1;
    addr:   std_logic_vector(31 downto 0);
  end record;
  
  signal jtag_state : jtag_state_t;

  signal cmd_empty,data_empty: std_logic;
  signal cmd_full,data_full:   std_logic;
  signal cmd_put,data_put:     std_logic;
  signal cmd_get,data_get:     std_logic;
  signal cmd_din,data_din:     std_logic_vector(31 downto 0);
  signal cmd_dout,data_dout:   std_logic_vector(31 downto 0);
  
  signal aclkn: std_logic;
  
  signal down_cnt: natural range 0 to 31;
  
 begin
  
  -- Slave FIFO
  slave_fifo_instance: slaveFIFO2b_fpga_top
  port map(
    aresetn => aresetn,
    aclk    => aclk,
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
  
  stub_input_proc: process
    file input_fp: text open read_mode is "../../io/input.txt";
    variable input_line : line;
    variable input_data : std_logic_vector(31 downto 0);
  begin
      cmd_gen_loop: while(endfile(input_fp) = false) loop
      cmd_put <= '0';
      wait for 15 ns;
      if(cmd_full='1')then
        wait until cmd_full='0';
      end if;
      readline(input_fp,input_line);
      hread(input_line,input_data);
      cmd_put <= '1';
      cmd_din <= input_data;
      wait for 10 ns;
    end loop cmd_gen_loop;
    cmd_put <='0';
    wait;
  end process;
   
  data_get <= '0', '1' after 80000 ns;

  -- Command FIFO
  cmd_fifo_inst: fifo_ram
  generic map(
    width => 32,
    addr_size => 4
  ) 
  port map(
    aclk     => aclk,
    aresetn  => aresetn,
    empty    => cmd_empty,
    full     => cmd_full,
    put      => cmd_put,
    get      => cmd_get,
    din      => cmd_din,
    dout     => cmd_dout
  );

  -- Data FIFO
  data_fifo_inst: fifo_ram
  generic map(
    width => 32,
    addr_size => 4
  ) 
  port map(
    aclk     => aclk,
    aresetn  => aresetn,
    empty    => data_empty,
    full     => data_full,
    put      => data_put,
    get      => data_get,
    din      => data_din,
    dout     => data_dout
  );
 
  -- JTAG converter
  jtag_state_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        jtag_state.st   <= idle;
        jtag_state.step <= 0;
      else
        case jtag_state.st is
          when idle =>
            if(cmd_empty='0') then
              jtag_state.st <= read_cmd;
            end if;
          when read_cmd =>
            if(cmd_empty='0') then
              jtag_state.st     <= read_addr;
              case cmd_dout(31 downto 28) is
                when x"1" =>  
                  jtag_state.op <= read;
                when x"0" =>
                  jtag_state.op <= write;
                when x"3" =>
                  jtag_state.op <= reset;
                when others =>
                  jtag_state.op <= reset;
              end case;
              jtag_state.size   <= to_integer(unsigned(cmd_dout(27 downto 24)));
              jtag_state.number <= to_integer(unsigned(cmd_dout(23 downto  0)));
            end if;
          when read_addr =>
            --if(jtag_state.op = write and cmd_empty='0') then
              jtag_state.st   <= run_cmd;
              jtag_state.addr <= cmd_dout; 
            --end if;
          when run_cmd =>
              if((jtag_state.op = write and cmd_empty='0') or jtag_state.op=read)then
                jtag_state.st <= wait_cmd;
              end if;
          when wait_cmd  =>
            if(cmd_empty='0' and jtag_busy='0') then
              case jtag_state.step is
                when NSTEPS-1 =>
                  jtag_state.st <= done;
                  jtag_state.step <= 0;
                  data_din      <= jtag_do(31 downto 0);
                when others =>
                  jtag_state.st <= run_cmd;
                  jtag_state.step <= jtag_state.step + 1;
              end case;
            end if;
          when done =>
            if(data_full='0') then
              jtag_state.st <= idle;
            end if;
          when others =>
              jtag_state.st <= idle;
        end case;
      end if;
    end if;
  end process jtag_state_proc;

  jtag_out_proc: process(jtag_state) is
  begin

    jtag_state_led <= "1000";
    jtag_shift_strobe <= '0';
    jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
    jtag_state_start  <= x"0";
    jtag_state_end    <= x"0";
    jtag_di           <= std_logic_vector(to_unsigned(0,32));
    cmd_get           <= '0';
    data_put          <= '0';
    
    case jtag_state.st is
      when idle =>
        jtag_state_led <= (others => '0');
        cmd_get        <= '1';
      when read_cmd =>
        jtag_state_led <= "0001";
        cmd_get        <= '1';
      when read_addr =>
        jtag_state_led <= "0010";
      when run_cmd | wait_cmd =>
        jtag_shift_strobe <= '1';
        case jtag_state.op is
           when reset =>
             jtag_state_start  <= TEST_LOGIC_RESET;
             jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
             jtag_state_end    <= TEST_LOGIC_RESET;
             jtag_di           <= std_logic_vector(to_unsigned(0,32));
           when read | write =>
           
             case jtag_state.step is
               when 0 => 
                 jtag_state_led <= "0011";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(4,16));
                 jtag_state_start  <= SHIFT_IR;
                 jtag_di           <= std_logic_vector(to_unsigned(11,32));
                 jtag_state_end    <= SHIFT_DR;
                 if(jtag_state.op = write and jtag_state.st = run_cmd)then
                   cmd_get <= '1';
                 end if;

               when 1 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(3,16));
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read) then jtag_di <= x"00000001"; else jtag_di <= x"00000000"; end if;
                 jtag_state_end    <= SHIFT_DR;
               when 2 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(32,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= x"11000001";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 3 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(3,16));
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read) then jtag_di <= x"00000003"; else jtag_di <= x"00000002"; end if;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 4 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(32,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= jtag_state.addr;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 5 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(3,16));
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read) then jtag_di <= x"00000007"; else jtag_di <= x"00000006"; end if;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 6 => 
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(32,16));
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read) then jtag_di <= x"00000000"; else jtag_di <= cmd_dout; end if;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when others =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,32));
                 jtag_state_led <= "0111";
             end case;
           when others =>
        end case;
      
      when done =>
        jtag_state_led <= "1000";
	data_put <= '1';
      when others =>
        jtag_state_led <= "1000";
        jtag_shift_strobe <= '0';
        jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
        jtag_state_start  <= x"0";
        jtag_state_end    <= x"0";
        jtag_di           <= std_logic_vector(to_unsigned(0,32));
        data_put          <= '0';
    end case;
  end process jtag_out_proc;

  jtag_ctrl_mater_inst: JTAG_Ctrl_Master
    port map(
      CLK          => aclk,
      aresetn      => aresetn,
      period       => period,
      BitCount     => jtag_bit_count,
      Shift_Strobe => jtag_shift_strobe,
      TDO          => TDO,
      TCK          => TCK,
      TMS          => TMS,
      TDI          => TDI,
      TRst         => TRST,
      Busy         => jtag_busy,
      StateStart   => jtag_state_start,
      StateEnd     => jtag_state_end,
      StateCurrent => jtag_state_current,
      Din          => jtag_di,
      Dout         => jtag_do
    );

  clk_original <= aclk;  
 -- aclkn <= not aclk;
 -- oddr_inst : ODDR2
 --   port map (   
 --     D0     => '0',                
 --     D1     => '1',
 --     C0     => aclk,
 --     C1     => aclkn,
 --     Q      => clk_out,
 --     CE     => '1',
 --     S      => '0',
 --     R      => '0'
 --   );     

  oddr2_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      clk_out <= '0';
    elsif(aclk'event and aclk='0')then
      clk_out <= '1';
    end if;
  end process oddr2_proc;
  
  -- LED outputs
  led <= jtag_state_current;
  
end architecture beh;



