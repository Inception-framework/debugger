library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_ram is
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
end entity;

architecture beh of fifo_ram is
  
  type ram_t is array(0 to (2**addr_size)-1) of std_logic_vector(width-1 downto 0);

  type state_t is record
    wr_ptr: natural range 0 to 2**addr_size-1;
    rd_ptr: natural range 0 to 2**addr_size-1;
    cnt:    natural range 0 to 2**addr_size;
    ram:    ram_t;
  end record;
  
  signal state: state_t;
  
begin
  
  state_proc: process(aclk)
  begin
    if(aclk'event and aclk='1')then
      if(aresetn='0')then
        state.wr_ptr <= 0;
        state.rd_ptr <= 0;
        state.cnt    <= 0;
      else
        case state.cnt is
          when 0 =>
            if(put='1')then
              state.cnt <= state.cnt + 1;
              if(state.wr_ptr = 2**addr_size-1)then
                state.wr_ptr <= 0;
              else
                state.wr_ptr <= state.wr_ptr + 1;
              end if;
              state.ram(state.wr_ptr) <= din;
            end if;
          when 2**addr_size =>
            if(get='1')then
              state.cnt <= state.cnt - 1;
              if(state.rd_ptr = 2**addr_size-1)then
                state.rd_ptr <= 0;
              else
                state.rd_ptr <= state.rd_ptr + 1;
              end if;
              dout <= state.ram(state.rd_ptr);
            end if;
          when others =>
            if(put='1' and get='0')then
              state.cnt <= state.cnt + 1;
            elsif(put='0' and get='1')then
              state.cnt <= state.cnt - 1;
            end if; 
        end case;

        if(state.cnt /= 2**addr_size)then
          if(put='1')then
            if(state.wr_ptr = 2**addr_size-1)then
              state.wr_ptr <= 0;
            else
              state.wr_ptr <= state.wr_ptr + 1;
            end if;
            state.ram(state.wr_ptr) <= din;
          end if;
        end if;
        if(state.cnt /= 0)then
          if(get='1')then
            if(state.rd_ptr = 2**addr_size-1)then
              state.rd_ptr <= 0;
            else
              state.rd_ptr <= state.rd_ptr + 1;
            end if;
            dout <= state.ram(state.rd_ptr);
          end if;
        end if;
      end if;
    end if;
  end process state_proc;
  
  empty <= '1' when state.cnt = 0 else '0';
  full  <= '1' when state.cnt = 2**addr_size else '0';
 
end architecture beh;
