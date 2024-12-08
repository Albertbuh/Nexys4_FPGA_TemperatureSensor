library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Temperature_Interface is
    Port (
        clk          : in  STD_LOGIC;               -- System clock
        reset        : in  STD_LOGIC;               -- Reset signal
        start        : in  STD_LOGIC;               -- Start signal for I2C transaction
        out_temp     : out INTEGER;                 -- Temperature value output
        busy         : out STD_LOGIC;               -- Indicates ongoing I2C transaction
        scl          : in STD_LOGIC;             -- I2C clock
        sda          : inout STD_LOGIC              -- I2C data
    );
end Temperature_Interface;

architecture Behavioral of Temperature_Interface is

    -- I2C State Machine States
    type state_type is (
        IDLE, START_COND, SEND_ADDR, SEND_REG, RESTART_COND,
        READ_MSB, READ_LSB, STOP_COND, DONE
    );
    signal state        : state_type := IDLE;

    -- Signals for I2C control
    signal sda_internal : STD_LOGIC := '1';         -- Internal SDA
    signal bit_counter  : INTEGER range 0 to 7 := 0; -- Bit position counter
    signal data         : STD_LOGIC_VECTOR(15 downto 0); -- Data to/from ADT7420

    -- Device and register constants
    constant SLAVE_ADDR : STD_LOGIC_VECTOR(6 downto 0) := "1001011"; -- ADT7420 address (0x4B)
    constant TEMP_REG   : STD_LOGIC_VECTOR(7 downto 0) := "00000000"; -- Temperature register address

    -- Clock divider for SCL generation (assume clk is much faster than I2C SCL)
    signal scl_counter  : INTEGER range 0 to 255 := 0; -- Counter for SCL frequency
    signal scl_enable   : STD_LOGIC := '0';            -- Enable signal for SCL toggle
    signal temp_value: INTEGER;
begin

    -- Assign internal SCL and SDA to top-level ports
    sda <= sda_internal;

    -- Generate SCL clock
    Clock: process(clk)
    begin
        if rising_edge(clk) then
            if scl_counter = 249 then -- Adjust based on system clock and desired SCL frequency
                scl_counter <= 0;
                scl_enable <= not scl_enable;
            else
                scl_counter <= scl_counter + 1;
            end if;
        end if;
    end process;

    -- I2C State Machine
    Main: process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            busy <= '0';
            sda_internal <= '1';
            bit_counter <= 0;
            data <= (others => '0');
        elsif rising_edge(clk) and scl_enable = '1' then
            case state is

                when IDLE =>
                    busy <= '0';
                    if start = '1' then
                        state <= START_COND;
                        busy <= '1';
                        sda_internal <= '0'; -- Generate Start Condition
                    end if;

                when START_COND =>
                    state <= SEND_ADDR;
                    bit_counter <= 0;

                when SEND_ADDR =>
                    if bit_counter < 7 then
                        sda_internal <= SLAVE_ADDR(bit_counter);
                        bit_counter <= bit_counter + 1;
                    else
                        sda_internal <= '0'; -- Write flag (R/W = 0)
                        bit_counter <= 0;
                        state <= SEND_REG;
                    end if;

                when SEND_REG =>
                    if bit_counter < 8 then
                        sda_internal <= TEMP_REG(bit_counter);
                        bit_counter <= bit_counter + 1;
                    else
                        state <= RESTART_COND;
                        sda_internal <= '1'; -- Release SDA
                        bit_counter <= 0;
                    end if;

                when RESTART_COND =>
                    sda_internal <= '0'; -- Generate Repeated Start
                    state <= READ_MSB;
                    bit_counter <= 0;

                when READ_MSB =>
                    if bit_counter < 8 then
                        data(15 - bit_counter) <= sda; -- Read MSB
                        bit_counter <= bit_counter + 1;
                    else
                        state <= READ_LSB;
                        bit_counter <= 0;
                    end if;

                when READ_LSB =>
                    if bit_counter < 8 then
                        data(7 - bit_counter) <= sda; -- Read LSB
                        bit_counter <= bit_counter + 1;
                    else
                        state <= STOP_COND;
                        bit_counter <= 0;
                    end if;

                when STOP_COND =>
                    sda_internal <= '0'; -- Generate Stop Condition
                    sda_internal <= '1';
                    state <= DONE;

                when DONE =>
                    temp_value <= to_integer(shift_right(signed(data), 3)) / 1600; -- Convert raw to temperature
                    state <= IDLE;
                    busy <= '0';

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;
    
    out_temp <= temp_value;

end Behavioral;
