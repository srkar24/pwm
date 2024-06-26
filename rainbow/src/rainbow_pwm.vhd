library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all; 

entity rainbow_pwm is
    port (
        clk : in std_logic;
        rst : in std_logic;
        sw : in std_logic_vector (3 downto 0);
        rgb : out std_logic_vector (2 downto 0));
end rainbow_pwm;

architecture Behavioral of rainbow_pwm is

    component pwm_enhanced is
        generic (
            R : integer := 8 
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            duty : in std_logic_vector (R downto 0); 
            dvsr : in std_logic_vector(31 downto 0);
            pwm_out : out std_logic
        );
    end component;

    signal pwm_Linear_reg : std_logic;
    signal pwm_negLinear_reg : std_logic;

    signal counter : integer;
    signal clk_50Hz : std_logic;
    constant clk_50Hz_half_cp : integer := 1250000; 
    constant resolution : integer := 8;
    constant dvsr : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(4882, 32)); 

    signal duty_linear : std_logic_vector(resolution downto 0);
    signal duty_neg_linear : std_logic_vector(resolution downto 0);

    -- Rainbow affect
    signal rainbow_cntr : std_logic_vector(2 downto 0); 
    signal red_reg : std_logic;
    signal green_reg : std_logic;
    signal blue_reg : std_logic;

begin

    --linear
    pwm_1 : pwm_enhanced generic map(R => resolution)
            port map(
                        clk => clk, rst => rst, dvsr => dvsr,
                        duty => duty_linear, 
                        pwm_out => pwm_Linear_reg);
    --rainbow
    pwm_3 : pwm_enhanced generic map(R => resolution)
            port map( 
                        clk => clk, rst => rst, dvsr => dvsr,
                        duty => duty_neg_linear,
                        pwm_out => pwm_negLinear_reg);

    --clk divider        
    process (clk, rst)
    begin
        if rst = '1' then
            counter <= 0;

            clk_50Hz <= '0';
        elsif rising_edge(clk) then
            if counter < clk_50Hz_half_cp then
                counter <= counter + 1;
            else
                counter <= 0;
                clk_50Hz <= not clk_50Hz;
            end if;
        end if;
    end process;

    --slow clock for linear
    process (clk_50Hz, rst)
    begin
        if rst = '1' then
            duty_linear <= (others => '0');
            rainbow_cntr <= (others => '0');
        elsif rising_edge(clk_50Hz) then
            if unsigned(duty_linear) <= 2 ** resolution then
                duty_linear <= std_logic_vector(unsigned(duty_linear) + 1);
            else
                duty_linear <= (others => '0');
                if (rainbow_cntr <= 5) then
                    rainbow_cntr <= rainbow_cntr + 1;
                else
                    rainbow_cntr <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --slow clock negative linear 
    process (clk_50Hz, rst)
    begin
        if rst = '1' then
            duty_neg_linear <= "011111111";
        elsif rising_edge(clk_50Hz) then
            if unsigned(duty_neg_Linear) >= 0 then
                duty_neg_linear <= std_logic_vector(unsigned(duty_neg_linear) - 1);
            else
                duty_neg_linear <= "011111111";
            end if;
        end if;
    end process;

    --rainbow affect
    process
    begin
        if sw = "0001" then
            if (rainbow_cntr = 0) then
                red_reg <= '1';
                green_reg <= pwm_linear_reg; 
                blue_reg <= '0';
            elsif (rainbow_cntr = 1) then
                red_reg <= pwm_negLinear_reg; 
                green_reg <= '1';
                blue_reg <= '0';
            elsif (rainbow_cntr = 2) then
                red_reg <= '0';
                green_reg <= '1';
                blue_reg <= pwm_Linear_reg; 
            elsif (rainbow_cntr = 3) then
                red_reg <= '0';
                green_reg <= pwm_negLinear_reg; 
                blue_reg <= '1';
            elsif (rainbow_cntr = 4) then
                red_reg <= pwm_Linear_reg; 
                green_reg <= '0';
                blue_reg <= '1';
            elsif (rainbow_cntr = 5) then
                red_reg <= '1';
                green_reg <= '0';
                blue_reg <= pwm_negLinear_reg; 
            else
                red_reg <= red_reg;
                green_reg <= green_reg;
                blue_reg <= blue_reg;
            end if;

        end if;
    end process;
    
    rgb(0) <= red_reg;
    rgb(1) <= green_reg;
    rgb(2) <= blue_reg;
    
end Behavioral;