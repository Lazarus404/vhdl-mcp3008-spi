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
-- Fle Name: mcp3008_adc.vhd
-- 
-- scope: MCP3008 controller
--
-- ver 0.01.2024.03.22
-- 
-- ******************************************************************** 
-- ******************************************************************** 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcp3008_adc is
  generic(
    CLK_DIV             : integer
  );
  port (
    i_clk               : in  std_logic;
    i_rstb              : in  std_logic;
    i_miso              : in  std_logic;
    o_mosi              : out std_logic;
    o_sclk              : out std_logic;
    o_cs                : out std_logic;
    o_pot_0             : out std_logic_vector(16 downto 0);
    o_pot_1             : out std_logic_vector(16 downto 0);
    o_pot_2             : out std_logic_vector(16 downto 0);
    o_pot_3             : out std_logic_vector(16 downto 0);
    o_pot_4             : out std_logic_vector(16 downto 0);
    o_pot_5             : out std_logic_vector(16 downto 0)
  );
end mcp3008_adc;

architecture rtl of mcp3008_adc is

constant N              : integer := 17;

component spi_controller
generic(
  N                     : integer;  -- number of bit to serialize
  CLK_DIV               : integer
);
port(
  i_clk                 : in  std_logic;
  i_rstb                : in  std_logic;
  o_sclk                : out std_logic;
  o_cs                  : out std_logic;
  o_mosi                : out std_logic;
  i_miso                : in  std_logic;
  i_tx_start            : in  std_logic;  -- start TX on serial line
  o_tx_end              : out std_logic;  -- TX data completed; o_data_parallel available
  i_buffer              : in  std_logic_vector(N-1 downto 0);  -- data to sent
  o_buffer              : out std_logic_vector(N-1 downto 0)   -- received data
);
end component;


type t_Pot is array (0 to 5) of std_logic_vector(N-1 downto 0);

signal r_tx_start       : std_logic;       -- start TX on serial line
signal r_tx_end         : std_logic;       -- TX data completed; o_data_parallel available
signal r_data_in        : std_logic_vector(N-1 downto 0);  -- data to sent
signal r_data_out       : std_logic_vector(N-1 downto 0);  -- received data
signal r_sclk           : std_logic;
signal r_cs             : std_logic;
signal r_mosi           : std_logic;
signal r_pots           : t_Pot := (others => (others => '1'));
signal p                : natural range 0 to 5 := 0;

signal mosi_test        : std_logic_vector(N-1 downto 0);  -- tx data
signal miso_test        : std_logic_vector(N-1 downto 0);  -- received data
signal count_rise       : integer;
signal count_fall       : integer;


begin

inst_spi_controller : spi_controller
generic map(
  N                => N,  -- number of bits to serialize
  CLK_DIV          => CLK_DIV
)
port map(
  i_clk            => i_clk,
  i_rstb           => i_rstb,
  o_sclk           => r_sclk,
  o_cs             => r_cs,
  o_mosi           => r_mosi,
  i_miso           => i_miso,
  i_tx_start       => r_tx_start,
  o_tx_end         => r_tx_end,
  i_buffer         => r_data_in,
  o_buffer         => r_data_out
);

--------------------------------------------------------------------
-- FSM
p_control : process(i_clk, i_rstb)
variable v_control         : unsigned(9 downto 0);
begin
  if (i_rstb = '0') then
    v_control         := (others=>'0');
    r_tx_start        <= '0';
    r_data_in         <= "11000" & std_logic_vector(to_unsigned(16#00#,N-5));
  elsif (rising_edge(i_clk)) then
    v_control         := v_control + 1;
    if (v_control = 10) then
      r_tx_start      <= '1';
    else
      r_tx_start      <= '0';
    end if;

    if (r_tx_end = '1') then
      r_data_in    <= "11000" &  std_logic_vector(to_unsigned(16#00#,N-5));
      r_pots(p)    <= r_data_out;
      --if (p = 5) then
      --  p          <= 0;
      --else
      --  p          <= p + 1;
      --end if;
    end if;
  end if;
end process p_control;


-- connect the external clock and reset to the internal signals
o_mosi      <= r_mosi;
o_cs        <= r_cs;
o_sclk      <= r_sclk;
o_pot_0     <= r_pots(0);
o_pot_1     <= r_pots(1);
o_pot_2     <= r_pots(2);
o_pot_3     <= r_pots(3);
o_pot_4     <= r_pots(4);
o_pot_5     <= r_pots(5);

end rtl;