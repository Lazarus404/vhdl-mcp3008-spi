--  ******************************************************************** 
--  ******************************************************************** 
--  
--  Coding style summary:
-- 
--   i_      input signal 
--   o_      output signal 
--   b_      bi-directional signal 
--   r_      register signal 
--   w_      wire signal (no registered logic) 
--   t_      user-Defined Type 
--   p_      pipe
--   pad_    pad used in the top level
--   g_      generic
--   c_      constant
--   state_  fsm state definition
--
-- ******************************************************************** 
--
-- Copyright ©2015 SURF-VHDL
--
-- ******************************************************************** 
--
-- Fle NUM_BITSame: spi_controller.vhd
-- 
-- scope: configurable SPI module
--
-- ver 0.01.2024.03.22
-- 
-- ******************************************************************** 
-- ******************************************************************** 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller is
generic(
  NUM_BITS              : integer := 10;                              -- number of bit to serialize
  CLK_DIV               : integer := 100 );                           -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(2*CLK_DIV)
 port (
  i_clk                 : in  std_logic;
  i_rst                 : in  std_logic;
  i_tx_start            : in  std_logic;                              -- start TX on serial line
  o_tx_end              : out std_logic;                              -- TX data completed; o_buffer available
  i_buffer              : in  std_logic_vector(NUM_BITS-1 downto 0);  -- data to sent
  o_buffer              : out std_logic_vector(NUM_BITS-1 downto 0);  -- received data
  o_sclk                : out std_logic;
  o_cs                  : out std_logic;
  o_mosi                : out std_logic;
  i_miso                : in  std_logic);
end spi_controller;

architecture rtl of spi_controller is

type t_spi_controller_fsm is (STATE_RESET, STATE_TX_RX, STATE_ENUM_BITSD);

signal r_clk_counter          : integer range 0 to CLK_DIV*2;
signal r_sclk_rise            : std_logic;
signal r_sclk_fall            : std_logic;
signal r_clk_counter_enabled  : std_logic;

signal r_counter_data         : integer range 0 to NUM_BITS;
signal w_tc_counter_data      : std_logic;
signal w_read                 : std_logic;

signal r_state_cur            : t_spi_controller_fsm;
signal w_state_next           : t_spi_controller_fsm;
signal r_tx_start             : std_logic;                              -- start TX on serial line
signal r_tx_data              : std_logic_vector(NUM_BITS-1 downto 0);  -- data to sent
signal r_rx_data              : std_logic_vector(NUM_BITS-1 downto 0);  -- received data

begin

w_tc_counter_data <= '0' when(r_counter_data > 0) else '1';

--------------------------------------------------------------------
-- FSM
p_state : process(i_clk, i_rst)
begin
  if (i_rst = '0') then
    r_state_cur                 <= STATE_RESET;
  elsif (rising_edge(i_clk)) then
    r_state_cur                 <= w_state_next;
  end if;
end process p_state;

p_fsm : process(
                  r_state_cur,
                  w_tc_counter_data,
                  r_tx_start,
                  r_sclk_rise,
                  r_sclk_fall
                )
begin
  case r_state_cur is
    when STATE_TX_RX          => 
      if (w_tc_counter_data = '1') and (r_sclk_rise = '1') then
        w_state_next            <= STATE_ENUM_BITSD;
      else
        w_state_next            <= STATE_TX_RX;
      end if;

    when STATE_ENUM_BITSD     => 
      if (r_sclk_fall='1') then
        w_state_next            <= STATE_RESET;  
      else
        w_state_next            <= STATE_ENUM_BITSD;  
      end if;

    when others               =>           -- STATE_RESET
      if (r_tx_start='1') then
        w_state_next            <= STATE_TX_RX ;
      else
        w_state_next            <= STATE_RESET ;
      end if;
  end case;
end process p_fsm;

p_transact : process(i_clk, i_rst)
begin
  if (i_rst = '0') then
    r_tx_start                  <= '0';
    o_tx_end                    <= '0';

    r_tx_data                   <= (others => '0');
    r_rx_data                   <= (others => '0');
    o_buffer                    <= (others => '0');
    
    r_counter_data              <= NUM_BITS-1;
    r_clk_counter_enabled       <= '0';

    o_sclk                      <= '1';
    o_cs                        <= '1';
    o_mosi                      <= '1';
  elsif (rising_edge(i_clk)) then
    r_tx_start                  <= i_tx_start;

    case r_state_cur is
      when STATE_TX_RX        =>
        o_tx_end                <= '0';
        r_clk_counter_enabled   <= '1';
        if (r_sclk_rise = '1') then
          o_sclk                <= '1';
          if (w_read = '1' and r_counter_data > 0) then
            r_rx_data           <= r_rx_data(NUM_BITS-2 downto 0) & i_miso;
            r_counter_data      <= r_counter_data - 1;
          end if;
          if (i_miso = '0' and w_read = '0') then
            w_read              <= '1';
          end if;
        elsif (r_sclk_fall = '1') then
          o_sclk                <= '0';
          o_mosi                <= r_tx_data(NUM_BITS-1);
          r_tx_data             <= r_tx_data(NUM_BITS-2 downto 0) & '1';
        end if;
        o_cs                    <= '0';

      when STATE_ENUM_BITSD   =>
        o_tx_end                <= r_sclk_fall;
        o_buffer                <= r_rx_data;
        r_counter_data          <= NUM_BITS-1;
        r_clk_counter_enabled   <= '1';
        o_cs                    <= '0';

      when others             =>           -- STATE_RESET
        r_tx_data               <= i_buffer;
        o_tx_end                <= '0';
        r_counter_data          <= NUM_BITS-1;
        r_clk_counter_enabled   <= '0';

        o_sclk                  <= '1';
        o_cs                    <= '1';
        o_mosi                  <= '1';
    end case;
  end if;
end process p_transact;


p_clk_counter : process(i_clk, i_rst)
begin
  if (i_rst = '0') then
    r_clk_counter               <= 0;
    r_sclk_rise                 <= '0';
    r_sclk_fall                 <= '0';
  elsif (rising_edge(i_clk)) then
    if (r_clk_counter_enabled = '1') then  -- sclk = '1' by default 
      if (r_clk_counter = CLK_DIV-1) then  -- firse edge = fall
        r_clk_counter           <= r_clk_counter + 1;
        r_sclk_rise             <= '0';
        r_sclk_fall             <= '1';
      elsif (r_clk_counter = (CLK_DIV*2)-1) then
        r_clk_counter           <= 0;
        r_sclk_rise             <= '1';
        r_sclk_fall             <= '0';
      else
        r_clk_counter           <= r_clk_counter + 1;
        r_sclk_rise             <= '0';
        r_sclk_fall             <= '0';
      end if;
    else
      r_clk_counter             <= 0;
      r_sclk_rise               <= '0';
      r_sclk_fall               <= '0';
    end if;
  end if;
end process p_clk_counter;

end rtl;
