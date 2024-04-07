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
-- Fle Name: top.vhd
-- 
-- scope: top level module for 6 potentiometers
--
-- ver 0.01.2024.03.22
-- 
-- ******************************************************************** 
-- ******************************************************************** 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity top is
  port (
    i_clk                    : in  std_logic;
    i_rstb                   : in  std_logic;
    i_miso                   : in  std_logic;
    o_mosi                   : out std_logic;
    o_sclk                   : out std_logic;
    o_cs                     : out std_logic;
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
end top;

architecture rtl of top is

constant N                   : integer := 10;

component mcp3008_adc
  generic(
    CLK_DIV                  : integer
  );
  port(
    i_clk                    : in  std_logic;
    i_rstb                   : in  std_logic;
    i_miso                   : in  std_logic;
    o_mosi                   : out std_logic;
    o_sclk                   : out std_logic;
    o_cs                     : out std_logic;
    o_pot_0                  : out std_logic_vector(N-1 downto 0);
    o_pot_1                  : out std_logic_vector(N-1 downto 0);
    o_pot_2                  : out std_logic_vector(N-1 downto 0);
    o_pot_3                  : out std_logic_vector(N-1 downto 0);
    o_pot_4                  : out std_logic_vector(N-1 downto 0);
    o_pot_5                  : out std_logic_vector(N-1 downto 0)
  );
end component;


constant CLK_DIV             : integer := 10;
constant interval_44_1kHz    : integer := 1129;    -- 1129 cycles for 44.1 kHz
signal clk_44_1kHz           : std_logic := '0';
signal clk_enable_counter    : natural range 0 to 1129 := 0;
signal r_sclk                : std_logic;
signal r_cs                  : std_logic;
signal r_mosi                : std_logic;
signal r_pot_0               : std_logic_vector(N-1 downto 0);
signal r_pot_1               : std_logic_vector(N-1 downto 0);
signal r_pot_2               : std_logic_vector(N-1 downto 0);
signal r_pot_3               : std_logic_vector(N-1 downto 0);
signal r_pot_4               : std_logic_vector(N-1 downto 0);
signal r_pot_5               : std_logic_vector(N-1 downto 0);


begin

inst_mcp3008_adc : mcp3008_adc
generic map(
  CLK_DIV          => CLK_DIV
)
port map(
  i_clk            => i_clk,
  i_rstb           => i_rstb,
  i_miso           => i_miso,
  o_mosi           => r_mosi,
  o_sclk           => r_sclk,
  o_cs             => r_cs,
  o_pot_0          => r_pot_0,
  o_pot_1          => r_pot_1,
  o_pot_2          => r_pot_2,
  o_pot_3          => r_pot_3,
  o_pot_4          => r_pot_4,
  o_pot_5          => r_pot_5
);


-- clock divider process (44.1 kHz)
p_clk_divider: process(i_clk)
begin
if (rising_edge(i_clk)) then
  if (clk_enable_counter >= interval_44_1kHz) then
    clk_44_1kHz        <= not clk_44_1kHz;
    clk_enable_counter <= 0;
  else
    clk_enable_counter <= clk_enable_counter + 1;
  end if;
end if;
end process p_clk_divider;


o_mosi   <= r_mosi;
o_cs     <= r_cs;
o_sclk   <= r_sclk;
o_led_00 <= r_pot_0(0);
o_led_01 <= r_pot_0(1);
o_led_02 <= r_pot_0(2);
o_led_03 <= r_pot_0(3);
o_led_04 <= r_pot_0(4);
o_led_05 <= r_pot_0(5);
o_led_06 <= r_pot_0(6);
o_led_07 <= r_pot_0(7);
o_led_08 <= r_pot_0(8);
o_led_09 <= r_pot_0(9);

end rtl;
