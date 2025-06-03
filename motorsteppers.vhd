LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY stepper_motor IS
PORT(
    clk        : in  std_logic;                          -- Clock sistem (misalnya 50 MHz)
    sw0        : in  std_logic;                          -- ON/OFF motor
    sw1        : in  std_logic;                          -- Arah (CW/CCW)
    sw2        : in  std_logic;                          -- Speed level 1 (lambat)
    sw3        : in  std_logic;                          -- Speed level 2 (sedang)
    sw4        : in  std_logic;                          -- Speed level 3 (cepat/turbo)
    btn_pulse  : in  std_logic;                          -- Tombol pulse untuk menyalakan motor
    step_out   : out std_logic_vector(3 downto 0)        -- Output ke driver stepper
);
END stepper_motor;

ARCHITECTURE behavior OF stepper_motor IS
    SIGNAL scount     : std_logic_vector(23 downto 0) := (others => '0'); -- counter pembagi clock
    SIGNAL step_idx   : std_logic_vector(1 downto 0) := "00";             -- index urutan step
    SIGNAL CA         : std_logic_vector(23 downto 0) := x"080000";       -- nilai divider
    SIGNAL motor_run  : std_logic := '0';                                 -- flag motor ON
BEGIN

    -- Pemilihan kecepatan berdasarkan switch prioritas
    process(sw2, sw3, sw4)
    begin
        if sw4 = '1' then
            CA <= x"010000";  -- turbo (paling cepat)
        elsif sw3 = '1' then
            CA <= x"030000";  -- sedang
        elsif sw2 = '1' then
            CA <= x"080000";  -- lambat
        else
            CA <= x"0F0000";  -- default sangat lambat
        end if;
    end process;

    -- Tombol pulse hanya untuk mengaktifkan motor_run (tidak bisa mematikan)
    process(clk)
    begin
        if rising_edge(clk) then
            if sw0 = '0' then
                motor_run <= '0';  -- reset saat SW0 OFF
            elsif sw0 = '1' and btn_pulse = '1' and motor_run = '0' then
                motor_run <= '1';  -- aktifkan motor sekali
            end if;
        end if;
    end process;

    -- Proses langkah motor stepper
    process(clk)
    begin
        if rising_edge(clk) then
            if motor_run = '1' then
                if scount >= CA then
                    scount <= (others => '0');

                    if sw1 = '1' then
                        step_idx <= step_idx + 1;  -- arah searah jarum jam
                    else
                        step_idx <= step_idx - 1;  -- arah berlawanan
                    end if;

                else
                    scount <= scount + 1;
                end if;
            else
                scount <= (others => '0');  -- reset counter jika motor off
            end if;
        end if;
    end process;

    -- Urutan pola aktivasi stepper 4-fase
    with step_idx select
        step_out <= "1001" when "00",  -- A+D
                    "1010" when "01",  -- B+D
                    "0110" when "10",  -- B+C
                    "0101" when "11",  -- A+C
                    "0000" when others; -- mati (default)

END behavior;
