library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Temperature_Display_System is
    Port (
        clk          : in  STD_LOGIC;               -- System clock
        reset        : in  STD_LOGIC;               -- Reset signal
        scl          : in STD_LOGIC;             -- I2C clock
        sda          : inout STD_LOGIC;             -- I2C data
        seg          : out STD_LOGIC_VECTOR (6 downto 0); -- 7-segment display segments
        an           : out STD_LOGIC_VECTOR (7 downto 0); -- 7-segment display anodes
        dp           : out STD_LOGIC                -- Decimal point
    );
end Temperature_Display_System;

architecture Structural of Temperature_Display_System is

    -- Signals for temperature sensor
    signal temp_raw      : INTEGER := 0;           -- Raw temperature value
    signal temp_celsius  : INTEGER := 0;           -- Temperature in Celsius
    signal start_reading : STD_LOGIC := '0';       -- Start signal for ADT7420
    signal busy          : STD_LOGIC := '0';       -- Busy signal from ADT7420

    -- Signals for 7-segment display
    signal display_value : INTEGER := 0;           -- Value to display on 7-segment
    signal refresh_clk   : STD_LOGIC := '0';       -- Clock for display refresh

    -- Clock divider for refreshing display
    signal refresh_counter : INTEGER range 0 to 99999 := 0;

begin

    -- Instantiate ADT7420 Interface
    TempSensor : entity work.Temperature_Interface
        port map (
            clk          => clk,
            reset        => reset,
            start        => start_reading,
            out_temp   => temp_raw,
            busy         => busy,
            scl          => scl,
            sda          => sda
        );

    -- Instantiate 7-Segment Display Controller
    DisplayUnit : entity work.Seven_Segment_Display
        port map (
            clk          => clk,
            reset        => reset,
            value        => display_value,
            seg          => seg,
            an           => an,
            dp           => dp
        );

    -- Generate slower clock for 7-segment refresh
    process(clk)
    begin
        if rising_edge(clk) then
            if refresh_counter = 99999 then
                refresh_counter <= 0;
                refresh_clk <= not refresh_clk;
            else
                refresh_counter <= refresh_counter + 1;
            end if;
        end if;
    end process;

    -- Main control process
    process(clk, reset)
    begin
        if reset = '1' then
            temp_celsius <= 0;
            display_value <= 0;
            start_reading <= '0';
        elsif rising_edge(clk) then
            -- Start temperature reading periodically
            if busy = '0' and start_reading = '0' then
                start_reading <= '1'; -- Trigger reading
            elsif start_reading = '1' then
                start_reading <= '0'; -- Clear start signal
            end if;

            -- Update temperature value once reading is complete
            if busy = '0' then
                temp_celsius <= temp_raw / 128; -- Convert raw value to Celsius
                display_value <= temp_celsius; -- Update display with temperature
            end if;
        end if;
    end process;

end Structural;
