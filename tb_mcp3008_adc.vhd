-- ******************************************************************** 
-- ******************************************************************** 
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
-- Fle Name: tb_mcp3008_adc.vhd
-- 
-- scope: test bench for mcp3008_adc.vhd
--
-- ver 0.01.2024.03.22
-- 
-- ******************************************************************** 
-- ******************************************************************** 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mcp3008_adc is
end tb_mcp3008_adc;

architecture rtl of tb_mcp3008_adc is

component mcp3008_adc
  generic(
    NUM_BITS            : integer := 10
  );
  port (
    i_clk               : in  std_logic;
    i_rst               : in  std_logic;
    i_miso              : in  std_logic;
    o_mosi              : out std_logic;
    o_busy              : out std_logic;
    b_sclk              : buffer std_logic;
    o_pot_0             : out std_logic_vector(9 downto 0);
    o_pot_1             : out std_logic_vector(9 downto 0);
    o_pot_2             : out std_logic_vector(9 downto 0);
    o_pot_3             : out std_logic_vector(9 downto 0);
    o_pot_4             : out std_logic_vector(9 downto 0);
    o_pot_5             : out std_logic_vector(9 downto 0)
  );
end component;

constant NUM_BITS       : integer := 10;   -- number of bit to serialize

signal i_clk            : std_logic := '0';
signal i_rst            : std_logic;
signal o_busy           : std_logic;
signal o_mosi           : std_logic;
signal i_miso           : std_logic := 'Z';
signal b_sclk           : std_logic;
signal o_pot_0          : std_logic_vector(NUM_BITS-1 downto 0);
signal o_pot_1          : std_logic_vector(NUM_BITS-1 downto 0);
signal o_pot_2          : std_logic_vector(NUM_BITS-1 downto 0);
signal o_pot_3          : std_logic_vector(NUM_BITS-1 downto 0);
signal o_pot_4          : std_logic_vector(NUM_BITS-1 downto 0);
signal o_pot_5          : std_logic_vector(NUM_BITS-1 downto 0);
signal mosi_test        : std_logic_vector(NUM_BITS-1 downto 0);  -- tx data
signal miso_test        : std_logic_vector(NUM_BITS-1 downto 0);  -- received data
signal finished         : std_logic := '0';

begin

i_clk     <= not i_clk after 10 ns when finished /= '1' else '0';
i_rst     <= '0', '1' after 163 ns;
finished  <= '1' after 1 ms;


u_mcp3008_adc : mcp3008_adc
generic map(
  NUM_BITS         => NUM_BITS
)
port map(
  i_clk            => i_clk,
  i_rst            => i_rst,
  i_miso           => i_miso,
  o_mosi           => o_mosi,
  o_busy           => o_busy,
  o_pot_0          => o_pot_0,
  o_pot_1          => o_pot_1,
  o_pot_2          => o_pot_2,
  o_pot_3          => o_pot_3,
  o_pot_4          => o_pot_4,
  o_pot_5          => o_pot_5
);

--------------------------------------------------------------------
-- FSM
p_control_sclk : process(b_sclk)
begin
  if (i_rst = '0') then
    miso_test   <= std_logic_vector(to_unsigned(16#C9#,NUM_BITS));
    mosi_test   <= std_logic_vector(to_unsigned(16#00#,NUM_BITS));
    i_miso      <= '0';
  else
    if (falling_edge(o_busy)) then
      miso_test <= std_logic_vector(to_unsigned(16#C9#,NUM_BITS));
    end if;
  end if;
end process p_control_sclk;


end rtl;
