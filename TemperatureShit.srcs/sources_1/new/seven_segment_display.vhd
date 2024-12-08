library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Seven_Segment_Display is
    Port (
        clk       : in  STD_LOGIC;  -- Clock signal
        reset     : in  STD_LOGIC;  -- Reset signal
        value     : in  INTEGER;    -- Input integer value
        seg       : out STD_LOGIC_VECTOR (6 downto 0); -- 7-segment display segments
        an        : out STD_LOGIC_VECTOR (7 downto 0); -- Anode control for 8 digits
        dp        : out STD_LOGIC   -- Decimal point control
    );
end Seven_Segment_Display;

architecture Behavioral of Seven_Segment_Display is

    -- Function to map BCD to 7-segment display encoding
    function bcd_to_7seg(bcd: STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
        variable segments : STD_LOGIC_VECTOR(6 downto 0);
    begin
        case bcd is
            when "0000" => segments := "1111110";  -- 0
            when "0001" => segments := "0110000";  -- 1
            when "0010" => segments := "1101101";  -- 2
            when "0011" => segments := "1111001";  -- 3
            when "0100" => segments := "0110011";  -- 4
            when "0101" => segments := "1011011";  -- 5
            when "0110" => segments := "1011111";  -- 6
            when "0111" => segments := "1110000";  -- 7
            when "1000" => segments := "1111111";  -- 8
            when "1001" => segments := "1111011";  -- 9
            when others => segments := "0000000";  -- Default (error case)
        end case;
        return segments;
    end function;

    signal digits      : STD_LOGIC_VECTOR(31 downto 0); -- 8 BCD digits
    signal digit_index : integer range 0 to 7 := 0;     -- Current digit index
    signal refresh_clk : STD_LOGIC; -- Slow clock for multiplexing
    signal seg_temp    : STD_LOGIC_VECTOR(6 downto 0); -- Temp 7-segment value
    signal dp_temp     : STD_LOGIC; -- Temp decimal point control

begin

    process(clk)
    begin
        if rising_edge(clk) then
            refresh_clk <= not refresh_clk;
        end if;
    end process;

    -- Convert the input integer to BCD digits
    integer_to_bcd: process(value)
        variable temp : INTEGER;
    begin
        temp := value;
        -- Extract 8 digits from the integer input
        digits(3 downto 0)    <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(7 downto 4)    <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(11 downto 8)   <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(15 downto 12)  <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(19 downto 16)  <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(23 downto 20)  <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(27 downto 24)  <= std_logic_vector(to_unsigned(temp mod 10, 4));
        temp := temp / 10;
        digits(31 downto 28)  <= std_logic_vector(to_unsigned(temp mod 10, 4));
    end process;

    -- Multiplex digits (extend to 8 digits)
    multiplexing: process(refresh_clk)
    begin
        if rising_edge(refresh_clk) then
            digit_index <= (digit_index + 1) mod 8;
        end if;
    end process;

    -- 7-segment encoding and decimal point control
    display: process(digit_index, digits)
    begin
        case digit_index is
            when 0 =>
                seg_temp <= bcd_to_7seg(digits(31 downto 28));
                dp_temp <= '1';  -- No decimal point
                an <= "01111111"; -- Enable the first anode
            when 1 =>
                seg_temp <= bcd_to_7seg(digits(27 downto 24));
                dp_temp <= '1';  -- No decimal point
                an <= "10111111"; -- Enable the second anode
            when 2 =>
                seg_temp <= bcd_to_7seg(digits(23 downto 20));
                dp_temp <= '1';  -- No decimal point here
                an <= "11011111"; -- Enable the third anode
            when 3 =>
                seg_temp <= bcd_to_7seg(digits(19 downto 16));
                dp_temp <= '1';  -- No decimal point
                an <= "11101111"; -- Enable the fourth anode
            when 4 =>
                seg_temp <= bcd_to_7seg(digits(15 downto 12));
                dp_temp <= '1';  -- No decimal point
                an <= "11110111"; -- Enable the fifth anode
            when 5 =>
                seg_temp <= bcd_to_7seg(digits(11 downto 8));
                dp_temp <= '1';  -- No decimal point
                an <= "11111011"; -- Enable the sixth anode
            when 6 =>
                seg_temp <= bcd_to_7seg(digits(7 downto 4));
                dp_temp <= '0';  -- Decimal point
                an <= "11111101"; -- Enable the seventh anode
            when 7 =>
                seg_temp <= bcd_to_7seg(digits(3 downto 0));
                dp_temp <= '1';  -- No decimal point
                an <= "11111110"; -- Enable the eighth anode
            when others =>
                seg_temp <= "0000000"; -- Blank
                dp_temp <= '1';
                an <= "11111111"; -- Disable all anodes
        end case;
    end process;

    -- Assign outputs
    seg <= seg_temp;
    dp <= dp_temp;

end Behavioral;
