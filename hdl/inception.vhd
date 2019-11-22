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

entity inception is
  port(
    aclk:       in std_logic;  -- Clock
    aresetn:    in std_logic;  -- Synchronous, active low, reset

    led:            out std_logic_vector(3 downto 0); -- LEDs
    jtag_state_led: out std_logic_vector(3 downto 0);

    sw:         in  std_logic_vector(4 downto 0); -- Slide switches

    irq_in:         in std_logic;
    irq_ack:        out std_logic;
    ----------------------
    -- jtag ctrl master --
    ----------------------
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
    sladdr         : out std_logic_vector(1 downto 0);
    sloe	   : out std_logic;                               ---output output enable select
    slop	   : out std_logic;                               ---output write select

    slwr_rdy	   : in std_logic;
    slwrirq_rdy	   : in std_logic;
    slrd_rdy	   : in std_logic

  );
end entity inception;

architecture beh of inception is

  -- Jtag ctrl signals
  signal jtag_bit_count:     std_logic_vector(15 downto 0);
  signal jtag_ir_count:      std_logic_vector(15 downto 0);
  signal jtag_dr_count:      std_logic_vector(15 downto 0);
  signal jtag_shift_strobe:  std_logic;
  signal jtag_busy:          std_logic;
  signal jtag_state_start:   std_logic_vector(3 downto 0);
  signal jtag_state_end:     std_logic_vector(3 downto 0);
  signal jtag_state_current: std_logic_vector(3 downto 0);
  signal jtag_di:            std_logic_vector(35 downto 0);
  signal jtag_do:            std_logic_vector(35 downto 0);

  component tristate is
   port (
     fdata_in : out std_logic_vector(31 downto 0);
     fdata    : inout std_logic_vector(31 downto 0);
     fdata_out_d : in std_logic_vector(31 downto 0);
     tristate_en_n : in std_logic
   );
  end component;
 
  component P_ODDR2 is
   port (
     aclk       : in std_logic;
     clk_out    : out std_logic;
     aresetn    : in std_logic
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
      daisy_normal_n            : in  std_logic;
      period                    : in  natural range 1 to 31;
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
      Din		        : in  STD_LOGIC_VECTOR (35 downto 0);
      Dout			: out STD_LOGIC_VECTOR (35 downto 0)
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

  signal cmd_empty,data_empty,irq_empty: std_logic;
  signal cmd_full,data_full,irq_full:   std_logic;
  signal cmd_put,data_put,irq_put:     std_logic;
  signal cmd_get,data_get,irq_get:     std_logic;
  signal cmd_din,data_din,irq_din:     std_logic_vector(31 downto 0);
  signal cmd_dout,data_dout,irq_dout:   std_logic_vector(31 downto 0);

  signal aclkn: std_logic;

  signal down_cnt: natural range 0 to 31;

  signal cmd_done: std_logic;

  -- fx3 interface
  signal tristate_en_n:                   std_logic;
  signal fdata_in,fdata_in_d,fdata_out_d: std_logic_vector(31 downto 0);
  signal slrd_rdy_d,slwr_rdy_d,slwrirq_rdy_d:           std_logic;

  type sl_state_t is (idle,prepare_read,prepare_write_irq,prepare_write_data,read1,read2,read3,read4,read5,write0,write1,write2);
  signal sl_state: sl_state_t;
  signal sl_is_irq: std_logic;

  -- irq
  signal irq_sync, irq_d1, irq_d2, irq_d3: std_logic;
  type irq_state_t is (idle,forward_event,done);
  signal irq_state: irq_state_t;
  signal irq_id_addr: std_logic_vector(31 downto 0);

  signal period: natural range 1 to 31;
  signal daisy_normal_n:  STD_LOGIC;

begin

  period <= to_integer(unsigned(sw(3 downto 0)));
  daisy_normal_n <= sw(4);

  -----------------------------
  -- irq address --------------
  -----------------------------
  irq_id_addr_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        if(daisy_normal_n='1')then
          irq_id_addr <= IRQ_ID_ADDR_DEFAULT_STM32L152RE;
	else
          irq_id_addr <= IRQ_ID_ADDR_DEFAULT_LPC1850;
	end if;
      end if;
    end if;
  end process irq_id_addr_proc;

  -----------------------------
  -- synchronize irq_in line --
  -----------------------------
  irq_sync <= irq_d3;
  irq_sync_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        irq_d1 <= '0';
	irq_d2 <= '0';
	irq_d2 <= '0';
      else
        irq_d1 <= irq_in;
	irq_d2 <= irq_d1;
	irq_d3 <= irq_d2;
      end if;
    end if;
  end process irq_sync_proc;

  -----------------------
  --irq_in state machine --
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

  ------------------------------------------------------------------
  -- local fifo to store irq id data coming from the jtag machine --
  ------------------------------------------------------------------
  irq_fifo_inst: fifo_ram
    generic map(
      width => 32,
      addr_size => 4
    )
    port map(
      aclk     => aclk,
      aresetn  => aresetn,
      empty    => irq_empty,
      full     => irq_full,
      put      => irq_put,
      get      => irq_get,
      din      => irq_din,
      dout     => irq_dout
    );

  -------------------------------------
  -- logic to interface with the fx3 --
  -------------------------------------

  tristate_inst: tristate
  port map(
    fdata_in      => fdata_in,
    fdata         => fdata,
    fdata_out_d   => fdata_out_d,
    tristate_en_n => tristate_en_n 
  );

  -- io flops
  input_flops_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        slrd_rdy_d <= '0';
	slwr_rdy_d <= '0';
	slwrirq_rdy_d <= '0';
	fdata_in_d <= (others=>'0');
      else
        slrd_rdy_d <= slrd_rdy;
	slwr_rdy_d <= slwr_rdy;
	slwrirq_rdy_d <= slwrirq_rdy;
	fdata_in_d <= fdata_in;
      end if;
    end if;
  end process input_flops_proc;


  -- state machine
  cmd_din <= fdata_in_d;
  cmd_put <= '1' when (sl_state=read5) else '0';
  fdata_out_d <= irq_dout when (sl_is_irq='1') else data_dout;
  data_get <= '1' when (sl_state=prepare_write_data) else '0';
  irq_get  <= '1' when (sl_state=prepare_write_irq ) else '0';
  --tristate_en_n <= '0' when (sl_state=write1) else '1';
  fx3_sl_master_fsm_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        sl_state <= idle;
	slop <= '0';
	sloe <= '0';
	tristate_en_n <= '1';
	sladdr <= "00";
	sl_is_irq <= '0';
      else
        case sl_state is
	  when idle =>
	    if(slwrirq_rdy_d='1' and irq_empty='0')then
              sl_state <= prepare_write_irq;
	      sladdr <= "01";
	      sl_is_irq <= '1';
	    elsif(slwr_rdy_d='1' and data_empty='0')then
	      sl_state <= prepare_write_data;
	      sladdr <= "00";
	      sl_is_irq <= '0';
	    elsif(slrd_rdy_d='1' and cmd_full='0')then
	      sl_state <= prepare_read;
	      sladdr <= "11";
	      sl_is_irq <= '0';
	    end if;
	  when prepare_read =>
            sl_state <= read1;
	    slop <= '1';
	    sloe <= '1';
          when prepare_write_data =>
	    sl_state <= write0;
	    tristate_en_n <= '0';
	  when prepare_write_irq =>
	    sl_state <= write0;
	    tristate_en_n <= '0';
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
	    tristate_en_n <= '1';
	    sladdr <= "00";
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
	      jtag_state.addr <= irq_id_addr;
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
                   when 4 =>
                     jtag_state.st <= write_back_h;
                   when others =>
                     jtag_state.st <= done_cmd;
                 end case;
               when others =>
                 jtag_state.st <= done_cmd;
               end case;
            end if;
          when write_back_h =>
            if((jtag_state.op=read_irq and irq_full='0') or (jtag_state.op=read and data_full='0'))then
              jtag_state.st <= write_back_l;
            end if;
          when write_back_l =>
            if((jtag_state.op=read_irq and irq_full='0') or (jtag_state.op=read and data_full='0'))then
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

  -- normal / daisy-chain selection
  jtag_chain_sel_proc: process(daisy_normal_n) is
  begin
    if(daisy_normal_n='1')then
      jtag_ir_count <= std_logic_vector(to_unsigned(9,16));
      jtag_dr_count <= std_logic_vector(to_unsigned(36,16));
    else
      jtag_ir_count <= std_logic_vector(to_unsigned(4,16));
      jtag_dr_count <= std_logic_vector(to_unsigned(35,16));
    end if;
  end process jtag_chain_sel_proc;

  jtag_out_proc: process(jtag_state,cmd_dout,jtag_do) is
  begin

    jtag_state_led <= "1111";
    jtag_shift_strobe <= '0';
    jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
    jtag_state_start  <= x"0";
    jtag_state_end    <= x"0";
    jtag_di           <= std_logic_vector(to_unsigned(0,36));
    cmd_get           <= '0';
    data_put          <= '0';
    irq_put           <= '0';
    data_din          <= (others=>'0');
    irq_din           <= (others=>'0');
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
                 jtag_di           <= std_logic_vector(to_unsigned(0,36));
               when 1 =>
                 jtag_bit_count    <= jtag_ir_count;
                 jtag_state_start  <= SHIFT_IR;
                 jtag_di           <= std_logic_vector(to_unsigned(0,36-9))&"11111"&x"a";
                 jtag_state_end    <= SHIFT_DR;
               when 2 =>
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= "0"&"01010000000000000000000000000000010";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 3 =>
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di           <= "0"&x"00000000"&"100";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 4 =>
                 jtag_state_led <= "0011";
                 jtag_bit_count    <= jtag_ir_count;
                 jtag_state_start  <= SHIFT_IR;
                 jtag_di           <= std_logic_vector(to_unsigned(0,36-9))&"11111"&x"b";
                 jtag_state_end    <= SHIFT_DR;
               when 5 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= "0"&x"22000002"&"000";
                 jtag_state_end    <= RUN_TEST_IDLE;

              when others =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,36));
            end case;
           when read | read_irq | write =>

             case jtag_state.step is
               when 0 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= "0"&jtag_state.addr&"010";
                 jtag_state_end    <= RUN_TEST_IDLE;
                 if(jtag_state.op = write and jtag_state.st = run_cmd)then
                   cmd_get <= '1';
                 end if;
              when 1 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(5,16));
                 jtag_state_start  <= RUN_TEST_IDLE;
                 jtag_di <= "0"&x"00000000"&"000";
                 jtag_state_end    <= RUN_TEST_IDLE;
              when 2 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 if(jtag_state.op = read or jtag_state.op = read_irq)then jtag_di <= "0"&cmd_dout&"111"; else jtag_di <= "0"&cmd_dout&"110"; end if;
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 3 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= std_logic_vector(to_unsigned(5,16));
                 jtag_state_start  <= RUN_TEST_IDLE;
                 jtag_di <= "0"&x"00000000"&"000";
                 jtag_state_end    <= RUN_TEST_IDLE;
               when 4 =>
                 jtag_state_led <= "0100";
                 jtag_bit_count    <= jtag_dr_count;
                 jtag_state_start  <= SHIFT_DR;
                 jtag_di <= "0"&x"00000000"&"111";
                 jtag_state_end    <= RUN_TEST_IDLE;
             when others =>
                 jtag_state_start  <= TEST_LOGIC_RESET;
                 jtag_bit_count    <= std_logic_vector(to_unsigned(1,16));
                 jtag_state_end    <= TEST_LOGIC_RESET;
                 jtag_di           <= std_logic_vector(to_unsigned(0,36));
                 jtag_state_led <= "0111";
             end case;
           when others =>
        end case;
      when write_back_h =>
        if(jtag_state.op = read)then
	  data_din <= x"0000000"&'0'&jtag_do(2 downto 0);
	  data_put <= '1';
	else
	  irq_din <= x"fffffff"&'0'&jtag_do(2 downto 0);
	  irq_put <= '1';
	end if;
      when write_back_l =>
	if(jtag_state.op = read)then
          data_din <= jtag_do(34 downto 3);
          data_put <= '1';
	else
          irq_din <= jtag_do(34 downto 3);
	  irq_put <= '1';
	end if;
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
        jtag_di           <= std_logic_vector(to_unsigned(0,36));
        data_put          <= '0';
        data_din          <= (others=>'0');
        cmd_done          <= '0';
    end case;
  end process jtag_out_proc;

  jtag_ctrl_mater_inst: JTAG_Ctrl_Master
    port map(
      CLK          => aclk,
      aresetn      => aresetn,
      daisy_normal_n => daisy_normal_n,
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

  ODDR2_inst: P_ODDR2
  port map(
    aclk      => aclk, 
    clk_out   => clk_out,
    aresetn   => aresetn
  );

  -- LED outputs
  led <= jtag_state_current;

end architecture beh;



