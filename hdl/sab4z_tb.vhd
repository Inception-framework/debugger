library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;

entity sab4z_tb is
end entity sab4z_tb;

architecture beh of sab4z_tb is

  signal  aclk:        std_logic;  -- Clock
  signal  aresetn:     std_logic;  -- Synchronous, active low, reset
  signal  btn:         std_logic;  -- Command button
  signal  sw:          std_logic_vector(3 downto 0); -- Slide switches
  signal  led:         std_logic_vector(3 downto 0); -- LEDs
  signal  jtag_state_led:  std_logic_vector(3 downto 0);
 
  signal  TDO		    :  STD_LOGIC;
  signal  TCK		    :  STD_LOGIC;
  signal  TMS		    :  STD_LOGIC;
  signal  TDI		    :  STD_LOGIC;
  signal  TRST      :  STD_LOGIC;
 
  signal  clk_out	   : std_logic;                               ---output clk 100 Mhz and 180 phase shift 
  signal  clk_original   : std_logic;      
  signal  slcs 	   : std_logic;                               ---output chip select
  signal  fdata          :  std_logic_vector(31 downto 0);         
  signal  faddr          :  std_logic_vector(1 downto 0);            ---output fifo address
  signal  slrd	   : std_logic;                               ---output read select
  signal  sloe	   : std_logic;                               ---output output enable select
  signal  slwr	   : std_logic;                               ---output write select
  signal  flaga	   : std_logic;                                
  signal  flagb	   : std_logic;
  signal  flagc	   : std_logic;
  signal  flagd	   : std_logic;
 
  signal  pktend	   :  std_logic;                               ---output pkt end 
  signal  mode_p     : std_logic_vector(2 downto 0);  
  
  -- Jtag ctrl signals
  signal jtag_bit_count:     std_logic_vector(15 downto 0);
  signal jtag_shift_strobe:  std_logic;
  signal jtag_busy:          std_logic;
  signal jtag_state_start:   std_logic_vector(3 downto 0);
  signal jtag_state_end:     std_logic_vector(3 downto 0);
  signal jtag_state_current: std_logic_vector(3 downto 0);
  signal jtag_di:       std_logic_vector(35 downto 0);
  signal jtag_do:       std_logic_vector(35 downto 0);

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
 
  signal aclkn : std_logic;
  signal clk:    std_logic;

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

  component slaveFIFO2b_fpga_top is
	port(
		aresetn : in std_logic;                                ---input reset active low
		aclk    : in std_logic;
		slcs 	   : out std_logic;                               ---output chip select
		fdata      : inout std_logic_vector(31 downto 0);         
		faddr      : out std_logic_vector(1 downto 0);            ---output fifo address
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
  end component;

  component JTAG_Ctrl_Master is
    Generic (
      Addrbreite  : natural := 10;  -- Speicherlänge = 2^Addrbreite
      Wortbreite  : natural := 8
    );
    Port (
      CLK			: in  STD_LOGIC;
      -- JTAG Part
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
 
  type jtag_st_t is (idle,read_cmd,read_addr,run_cmd,wait_cmd,done);
  type jtag_op_t is (read,write);
  type jtag_state_t is record
    st: jtag_st_t;
    op: jtag_op_t;
    step:   natural range 0 to 6;
    size:   natural range 1 to 4;
    number: natural range 0 to 2**24-1;
    addr:   std_logic_vector(31 downto 0);
  end record;
  
  signal jtag_state : jtag_state_t;
  
 begin
  
  aresetn <= '0', '1' after 5 ns;
  clk_proc: process is
  begin
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process clk_proc;   

  jtag_state_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        jtag_state.st   <= idle;
        jtag_state.op   <= write;
        jtag_state.step <= 0;
      else
        case jtag_state.st is
          when idle =>
            if(btn_re='1') then
              jtag_state.st <= read_cmd;
            end if;
          when read_cmd =>
            if(btn_re='1') then
              jtag_state.st     <= read_addr;
              if(r(28)='1') then 
                jtag_state.op <= read;
              else 
                jtag_state.op <= write;
              end if;
              jtag_state.size   <= to_integer(unsigned(std_logic_vector(r(27 downto 24))));
              jtag_state.number <= to_integer(unsigned(std_logic_vector(r(23 downto  0))));
            end if;
          when read_addr =>
            if(btn_re='1') then
              jtag_state.st   <= run_cmd;
              jtag_state.addr <= std_logic_vector(r); 
            end if;
          when run_cmd =>
              jtag_state.st <= wait_cmd;
          when wait_cmd  =>
            if(btn_re='1' and jtag_busy='0') then
              jtag_state.step <= jtag_state.step + 1;
              case jtag_state.step is
                when 3 =>
                  jtag_state.st <= done;
                  status        <= std_ulogic_vector(jtag_do(31 downto 0));
                when others =>
                  jtag_state.st <= run_cmd;
              end case;
            end if;
          when done =>
            if(btn_re='1') then
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
    jtag_shift_strobe <= '0';
    case jtag_state.st is
      when idle =>
        jtag_state_led <= (others => '0');
      when read_cmd =>
        jtag_state_led <= "0001";
      when read_addr =>
        jtag_state_led <= "0010";
      when run_cmd =>
        jtag_shift_strobe <= '1';
        case jtag_state.step is
          when 0 => 
            jtag_state_led <= "0011";
            jtag_bit_count    <= std_logic_vector(to_unsigned(4,16));
            jtag_state_start  <= x"b";
            jtag_state_end    <= x"4";
            jtag_di           <= std_logic_vector(to_unsigned(11,36));
          when 1 => 
            jtag_state_led <= "0100";
            jtag_bit_count    <= std_logic_vector(to_unsigned(36,16));
            jtag_state_start  <= x"4";
            jtag_state_end    <= x"0";
            jtag_di           <= "0000"&std_logic_vector(r);
          when 2 => 
            jtag_state_led <= "0101";
            jtag_bit_count    <= std_logic_vector(to_unsigned(36,16));
            jtag_state_start  <= x"4";
            jtag_state_end    <= x"0";
            jtag_di           <= "0100"&std_logic_vector(r);
          when 3 => 
            jtag_state_led <= "0110";
            jtag_bit_count    <= std_logic_vector(to_unsigned(36,16));
            jtag_state_start  <= x"4";
            jtag_state_end    <= x"0";
            jtag_di           <= "1100"&std_logic_vector(r);
          when others =>
            jtag_state_led <= "0111";
            jtag_bit_count    <= std_logic_vector(to_unsigned(0,16));
            jtag_state_start  <= x"0";
            jtag_state_end    <= x"0";
            jtag_di           <= std_logic_vector(to_unsigned(0,36));
        end case;
      when wait_cmd =>
        jtag_state_led <= "1000";
      when others =>
        jtag_shift_strobe <= '0';
    end case;
  end process jtag_out_proc;

  jtag_ctrl_mater_inst: JTAG_Ctrl_Master
    port map(
      CLK          => aclk,
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

  sl_inst: slaveFIFO2b_fpga_top 
    port map(
      aresetn => aresetn,
      aclk    => aclk,
      slcs    => slcs,
      fdata   => fdata,         
      faddr   => faddr,
      slrd    => slrd,
      sloe    => sloe,
      slwr    => slwr,
          
      flaga   => flaga,	                                  
      flagb   => flagb,	   
      flagc   => flagc,	   
      flagd   => flagd,	   
      
      
      pktend  => pktend,
      mode_p  => mode_p   
   );

  clk_original <= aclk;  
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
  led <= jtag_state_current;
  
   
end architecture beh;

