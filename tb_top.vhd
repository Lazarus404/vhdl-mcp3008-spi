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
-- Copyright ©2024 Jahred Love
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

entity tb_top is
end tb_top;

architecture rtl of tb_top is

component top
port (
  i_clk                    : in  std_logic;
  i_rst                    : in  std_logic;
  i_miso                   : in  std_logic;
  o_mosi                   : out std_logic;
  o_sclk                   : out std_logic;
  o_busy                   : out std_logic;
  o_led_00                 : out std_logic;
  o_led_01                 : out std_logic;
  o_led_02                 : out std_logic;
  o_led_03                 : out std_logic;
  o_led_04                 : out std_logic;
  o_led_05                 : out std_logic;
  o_led_06                 : out std_logic;
  o_led_07                 : out std_logic;
  o_led_08                 : out std_logic;
  o_led_09                 : out std_logic
);
end component;


constant NUM_BITS          : integer   := 10;
signal i_clk               : std_logic := '0';
signal i_rst               : std_logic := '0';
signal i_miso              : std_logic := '0';
signal o_mosi              : std_logic;
signal o_sclk              : std_logic;
signal o_busy              : std_logic;
signal o_led_00            : std_logic;
signal o_led_01            : std_logic;
signal o_led_02            : std_logic;
signal o_led_03            : std_logic;
signal o_led_04            : std_logic;
signal o_led_05            : std_logic;
signal o_led_06            : std_logic;
signal o_led_07            : std_logic;
signal o_led_08            : std_logic;
signal o_led_09            : std_logic;
signal mosi_test           : std_logic_vector(9 downto 0);  -- tx data
signal miso_test           : std_logic_vector(9 downto 0);  -- received data

signal finished            : std_logic := '0';

begin

i_clk     <= not i_clk after 10 ns when finished /= '1' else '0';
i_rst     <= '0', '1' after 163 ns;
finished  <= '1' after 1 ms;


u_top : top
port map(
  i_clk            => i_clk,
  i_rst            => i_rst,
  i_miso           => i_miso,
  o_mosi           => o_mosi,
  o_sclk           => o_sclk,
  o_busy           => o_busy,
  o_led_00         => o_led_00,
  o_led_01         => o_led_01,
  o_led_02         => o_led_02,
  o_led_03         => o_led_03,
  o_led_04         => o_led_04,
  o_led_05         => o_led_05,
  o_led_06         => o_led_06,
  o_led_07         => o_led_07,
  o_led_08         => o_led_08,
  o_led_09         => o_led_09
);


--------------------------------------------------------------------
-- FSM
p_control_sclk : process(o_sclk)
begin
  if (i_rst = '0') then
    miso_test   <= "0110000000";
    mosi_test   <= "0000000000";
    i_miso      <= '0';
  else
    if (falling_edge(o_busy)) then
      miso_test <= std_logic_vector(to_unsigned(16#C9#,NUM_BITS));
    end if;
  end if;
end process p_control_sclk;


end rtl;
