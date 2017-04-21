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

--library UNISIM;
--use UNISIM.vcomponents.all;

entity inception is
  port(
    aclk:       in std_logic;  -- Clock
    aresetn:    in std_logic;  -- Synchronous, active low, reset

    btn1_re,btn2_re:in std_logic;  -- Command button
    sw:             in  std_logic_vector(3 downto 0); -- Slide switches
    led:            out std_logic_vector(3 downto 0); -- LEDs
    jtag_state_led: out std_logic_vector(3 downto 0);
    r:              in std_ulogic_vector(31 downto 0);
    status:         out std_ulogic_vector(31 downto 0);

    irq:            in std_logic;
    irq_ack:        out std_logic;
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
end entity inception;

architecture beh of inception is

  -- Jtag ctrl signals
  signal jtag_bit_count:     std_logic_vector(15 downto 0);
  signal jtag_shift_strobe:  std_logic;
  signal jtag_busy:          std_logic;
  signal jtag_state_start:   std_logic_vector(3 downto 0);
  signal jtag_state_end:     std_logic_vector(3 downto 0);
  signal jtag_state_current: std_logic_vector(3 downto 0);
  signal jtag_di:       std_logic_vector(34 downto 0);
  signal jtag_do:       std_logic_vector(34 downto 0);

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
      Din		        : in  STD_LOGIC_VECTOR (34 downto 0);
      Dout			: out STD_LOGIC_VECTOR (34 downto 0)
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



  type jtag_st_t is (idle,idle2,read_cmd,read_addr,run_cmd,wait_cmd,write_back_h,write_back_l,done_cmd,done);
  type jtag_op_t is (read,read_irq,write,reset);
  type jtag_state_t is record
    st: jtag_st_t;
    op: jtag_op_t;
    step:   natural range 0 to NSTEPS_RST-1;
    size:   natural range 0 to 4;
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

  signal cmd_done: std_logic;

  -- fx3 interface
  signal tristate_en_n:                   std_logic;
  signal fdata_in,fdata_in_d,fdata_out_d: std_logic_vector(31 downto 0);
  signal slrd_rdy_d,slwr_rdy_d:           std_logic;
  
  type sl_state_t is (idle,read1,read2,read3,read4,read5,write0,write1,write2);
  signal sl_state: sl_state_t;

  -- irq
  signal irq_sync, irq_d1, irq_d2, irq_d3: std_logic;
  type irq_state_t is (idle,forward_event,done);
  signal irq_state : irq_state_t;

 begin

  --------------------------
  -- synchronize irq line --
  --------------------------
  irq_sync <= irq_d3;
  irq_sync_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        irq_d1 <= '0';
	irq_d2 <= '0';
	irq_d2 <= '0';
      else
        irq_d1 <= irq;
	irq_d2 <= irq_d1;
	irq_d3 <= irq_d2;
      end if;
    end if;
  end process irq_sync_proc;

  -----------------------
  -- irq state machine --
  -----------------------
  irq_ack <= '1' when irq_state = done else '0';
  irq_fsm_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
	irq_state <= idle;
      else
        case irq_state is
	  when idle =>
	    if(irq_sync='1')then
	      irq_state <= forward_event;
	    end if;
	  when forward_event =>
	    if(cmd_done='1')then
	      irq_state <= done;
	    end if;
	  when done =>
	    if(irq_sync='0')then
	      irq_state <= idle;
	    end if;
	  when others =>
	    irq_state <= done;
	end case;
      end if;
    end if;
  end process irq_fsm_proc;


  --------------------------------------------------------
  -- local fifo to store commands reveived from the fx3 --
  --------------------------------------------------------
  cmd_fifo_inst : fifo_ram
    generic map(
      width => 32,
      addr_size => 4
    )
    port map(
      aclk => aclk,
      aresetn => aresetn,
      empty => cmd_empty,
      full => cmd_full,
      put => cmd_put,
      get => cmd_get,
      din => cmd_din,
      dout => cmd_dout
    );

  -------------------------------------------------------------
  -- local fifo to store data received from the jtag machine --
  -------------------------------------------------------------
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
 
  -------------------------------------
  -- logic to interface with the fx3 --
  -------------------------------------

  -- tristate buffer simulation
  tristate_sim_gen: if(SIM_SYN_N=true)generate
    fdata_in <= fdata;
    fdata <= (others=>'Z') when tristate_en_n='1' else fdata_out_d;
  end generate;

  -- tristate buffer synthesis on Xilinx Zedboard
  --tristate_syn_gen: if(SIM_SYN_N=false)generate
  --  tristate_gen_loop: for i in 0 to 31 generate
  --    tristate_buf_i : IOBUF
  --      port map (
  --        O     => fdata_in(i),
  --        IO    => fdata(i),
  --        I     => fdata_out_d(i),
  --        T     => tristate_en_n
  --      );
  --  end generate tristate_gen_loop;
  --end generate;

  -- io flops
  input_flops_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        slrd_rdy_d <= '0';
	slwr_rdy_d <= '0';
	fdata_in_d <= (others=>'0');
	status <= (others=>'0');
      else
        slrd_rdy_d <= slrd_rdy;
	slwr_rdy_d <= slwr_rdy;
	fdata_in_d <= fdata_in;
	if(cmd_put='1')then
	  status <= std_ulogic_vector(cmd_din);
	end if;
      end if;
    end if;
  end process input_flops_proc;


  -- state machine
  cmd_din <= fdata_in_d;
  cmd_put <= '1' when (sl_state=read5) else '0';
  fdata_out_d <= data_dout;
  data_get <= '1' when (sl_state=idle and slwr_rdy_d='1' and data_empty='0') else '0'; -- MEALY!!! 
  --tristate_en_n <= '0' when (sl_state=write1) else '1';
  fx3_sl_master_fsm_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        sl_state <= idle;
	slop <= '0';
	sloe <= '0';
	tristate_en_n <= '1';
      else
        case sl_state is
	  when idle =>
	    if(slwr_rdy_d='1' and data_empty='0')then
	      sl_state <= write0;
	      tristate_en_n <= '0';
	    elsif(slrd_rdy_d='1' and cmd_full='0')then
	      sl_state <= read1;
	      slop <= '1';
	      sloe <= '1';
	    end if;
	  when read1 =>
	    sl_state <= read2;
	    slop <= '0';
	  when read2 =>
	    sl_state <= read3;
	  when read3 =>
	    sl_state <= read4;
	  when read4 =>
	    sl_state <= read5;
	    sloe <= '0';
	  when read5 =>
	    sl_state <= idle;
	 -- when read6 =>
	 --   sl_state <= read7;
	 -- when read7 =>
	 --   sl_state <= read8;
	 -- when read8 =>
	 --   sl_state <= idle;
	  when write0 =>
	    sl_state <= write1;
	    slop <= '1';
	  when write1 =>
	    sl_state <= write2;
	    slop <= '0';
	    tristate_en_n <= '1';
          when write2 =>
	    sl_state <= idle;
	  when others =>
	    sl_state <= idle;
	    slop <= '0';
	    sloe <= '0';
	end case;
      end if;
    end if;
  end process fx3_sl_master_fsm_proc;

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
	    if(irq_state = forward_event)then
	      jtag_state.st <= run_cmd;
	      jtag_state.op <= read_irq;
	      jtag_state.addr <= std_logic_vector(r);
	    elsif(cmd_empty='0')then 
	      jtag_state.st <= idle2;
	    end if;
	  when idle2 =>
            jtag_state.st <= read_cmd;
          when read_cmd =>
            if(cmd_empty='0') then
              jtag_state.st     <= read_addr;
              case cmd_dout(31 downto 28) is
                when x"2" =>
                  jtag_state.op <= read;
                when x"1" =>
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
              --if((jtag_state.op = write and cmd_empty='0') or jtag_state.op=read or jtag_state.op=reset)then
                jtag_state.st <= wait_cmd;
              --end if;
              if(jtag_state.op = write and jtag_state.step = 0 and cmd_empty='1')then
                jtag_state.st <= run_cmd;
              end if;
          when wait_cmd  =>
            if(jtag_busy = '0')then
              case jtag_state.op is
                when reset | write =>
                 jtag_state.st <= done_cmd;
                 -- case jtag_state.step is
                 --   when 1 =>
                 --     jtag_state.st <= write_back_l;
                 --   when 0 | 4  =>
                 --     jtag_state.st <= done_cmd;
                 --   when others =>
                 --     jtag_state.st <= write_back_h;
                 -- end case;
               when read | read_irq =>
                 case jtag_state.step is
                   when 3 =>
                     jtag_state.st <= write_back_h;
                   when others =>
                     jtag_state.st <= done_cmd;
                 end case;
               when others =>
                 jtag_state.st <= done_cmd;
               end case;
            end if;
          when write_back_h =>
            if(data_full='0')then
              jtag_state.st <= write_back_l;
            end if;
          when write_back_l =>
            if(data_full='0')then
              jtag_state.st <= done_cmd;
            end if;
          when done_cmd =>
            --if(cmd_empty='0') then
              case jtag_state.step is
                when NSTEPS_WR-1 =>
                  if(jtag_state.op = write)then
                    jtag_state.st <= done;
                    jtag_state.step <= 0;
                  else
                    jtag_state.st <= run_cmd;
                    jtag_state.step <= jtag_state.step + 1;
                  end if;
		when NSTEPS_RD-1 =>
	          if(jtag_state.op = read or jtag_state.op = read_irq)then
                    jtag_state.st <= done;
                    jtag_state.step <= 0;
                  else
                    jtag_state.st <= run_cmd;
                    jtag_state.step <= jtag_state.step + 1;
                  end if;
                when NSTEPS_RST-1 =>
                  jtag_state.st <= done;
                  jtag_state.step <= 0;
                when others =>
                  jtag_state.st <= run_cmd;
                  jtag_state.step <= jtag_state.step + 1;
               end case;
            --end if;
          when done =>
            --if(data_full='0') then
              jtag_state.st <= idle;
            --end if;
          when others =>
              jtag_state.st <= idle;
        end case;
      end if;
    end if;
  end process jtag_state_proc;

  jtag_out_proc: process(jtag_state,cmd_dout,jtag_do) is
  begin

    jtag_state_led <= "1111";
    jtag_shift_strobe <= '0';
    jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
    jtag_state_start  <= x"0";
    jtag_state_end    <= x"0";
    jtag_di           <= std_logic_vector(to_unsigned(0,35));
    cmd_get           <= '0';
    data_put          <= '0';
    data_din          <= (others=>'0');
    cmd_done          <= '0';

    case jtag_state.st is
      when idle  =>
        jtag_state_led <= (others=> '0');
      when idle2 =>
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
             case jtag_state.step is
               when 0 =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,35));
                when 1 =>
                 jtag_bit_count    <= std_logic_vector(to_unsigned(4,16));
                 jtag_state_start  <= SHIFT_IR;
                 jtag_di           <= std_logic_vector(to_unsigned(10,35));
                 jtag_state_end    <= SHIFT_DR;
               when 2 =>
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= "01010000000000000000000000000000010";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 3 =>
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= x"00000000"&"100";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 4 =>
                 jtag_state_led <= "0011";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(4,16));
                 jtag_state_start  <= SHIFT_IR;
                 jtag_di           <= std_logic_vector(to_unsigned(11,35));
                 jtag_state_end    <= SHIFT_DR;
               when 5 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= x"22000002"&"000";
                 jtag_state_end    <= RUN_TEST_IDLE;

              when others =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,35));
            end case;
           when read | read_irq | write =>

             case jtag_state.step is
               when 0 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= jtag_state.addr&"010";
                 jtag_state_end    <= RUN_TEST_IDLE;
                 if(jtag_state.op = write and jtag_state.st = run_cmd)then
                   cmd_get <= '1';
                 end if;
               when 1 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read or jtag_state.op = read_irq)then jtag_di <= cmd_dout&"111"; else jtag_di <= cmd_dout&"110"; end if;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 2 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(5,16));
                 jtag_state_start  <= RUN_TEST_IDLE;
                 jtag_di <= x"00000000"&"000";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 3 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(35,16));
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= x"00000000"&"110";
                 jtag_state_end    <= RUN_TEST_IDLE;
             when others =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,35));
                 jtag_state_led <= "0111";
             end case;
           when others =>
        end case;
      when write_back_h =>
        if(jtag_state.op = read)then data_din <= x"0000000"&'0'&jtag_do(2 downto 0); else data_din <= x"fffffff"&'0'&jtag_do(2 downto 0); end if;
        data_put <= '1';
      when write_back_l =>
        data_din <= jtag_do(34 downto 3);
        data_put <= '1';
      when done =>
        jtag_state_led <= "1000";
	if(jtag_state.op = read_irq)then
          cmd_done <= '1';
	end if;
      when others =>
        jtag_state_led <= "1111";
        jtag_shift_strobe <= '0';
        jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
        jtag_state_start  <= x"0";
        jtag_state_end    <= x"0";
        jtag_di           <= std_logic_vector(to_unsigned(0,35));
        data_put          <= '0';
        data_din          <= (others=>'0');
        cmd_done          <= '0';
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


 clk_out_syn_gen: if SIM_SYN_N = false generate
   aclkn <= not aclk;
   oddr_inst : ODDR2
     port map (
       D0     => '0',
       D1     => '1',
       C0     => aclk,
       C1     => aclkn,
       Q      => clk_out,
       CE     => '1',
       S      => '0',
       R      => '0'
     );
  end generate clk_out_syn_gen;

  clk_out_sim_gen: if SIM_SYN_N generate
    oddr2_proc: process(aclk)
    begin
      if(aclk'event and aclk='1')then
        clk_out <= '0';
      elsif(aclk'event and aclk='0')then
        clk_out <= '1';
      end if;
    end process oddr2_proc;
  end generate clk_out_sim_gen;

  -- LED outputs
  led <= jtag_state_current;

end architecture beh;



