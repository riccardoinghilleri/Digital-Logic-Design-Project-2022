----------------------------------------------------------------------------------
--
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice
--
-- Progetto svolto da: Riccardo Inghilleri (Codice Persona 10713236 - Matricola 937011)
--
-- Module Name: project_reti_logiche
--  
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state_type is (
        START,
        READ_N_WORDS,
        READ,
        CONV,
        WRITE_MEM,
        DISABLE_WRITING,
        DONE
        ); 
        
    type state_conv is (
        S00,
        S01,
        S10,
        S11
        );
        
    signal next_state: state_type := START;
    signal current_state: state_type := START;
    signal next_state_conv: state_conv := S00;
    signal current_state_conv: state_conv := S00;
    signal conv_en: std_logic := '0';
    signal conv_rst: std_logic := '0';
    signal curr_addr: UNSIGNED(15 downto 0) := "0000000000000000";
    signal read_addr: UNSIGNED(15 downto 0) := "0000000000000000";
    signal write_addr: UNSIGNED(15 downto 0) := "0000001111101000";
    signal n_words: UNSIGNED(7 downto 0) := "00000000";
    signal counter: UNSIGNED(3 downto 0) := "0000";
    signal w: std_logic_vector(7 downto 0) := "00000000";
    signal u: std_logic := '0';
    signal z: std_logic_vector(7 downto 0) := "00000000";
    
begin

    o_address <= std_logic_vector(curr_addr);
    
    -- FSM   
    fsm_state_reg: process(i_clk, i_rst) 
    begin 
        if (i_rst = '1') then 
            current_state <= START; 
        elsif (rising_edge(i_clk)) then 
            current_state <= next_state; 
        end if; 
    end process;
        
    -- FSM    
    fsm_delta_lambda: process(i_clk, i_rst, current_state, i_start)
    begin
        if (falling_edge(i_clk)) then
            case current_state is
                
                when START =>
                    curr_addr <= "0000000000000000";
                    counter <= "0000";
                    write_addr <= "0000001111101000"; 
                    n_words <= "00000000";
                    conv_en <= '0';
                    conv_rst <= '0';
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '0';
                    next_state <= START;              
                    if(i_start = '1' AND i_rst = '0') then 
                        o_en <= '1';
                        next_state <= READ_N_WORDS;
                    end if;
                                      
                when READ_N_WORDS =>
                    n_words <= UNSIGNED(i_data); 
                    curr_addr <= curr_addr +1;
                    next_state <= READ; 
                                          
                when READ => 
                    if (n_words="00000000") then 
                        next_state <= DONE;
                    else
                        w <= i_data; 
                        curr_addr <= curr_addr + 1;
                        next_state <= CONV;
                    end if;
                       
                when CONV => 
                    conv_en <= '1';
                    u <= w(7);
                    w <= w(6 downto 0) & '0';  
                    counter <= counter+1;
                    if(counter = "0100") then
                        conv_en <= '0';
                        read_addr <= curr_addr; 
                        curr_addr <= write_addr;
                        next_state <= WRITE_MEM;
                    elsif(counter="1000") then 
                        conv_en <= '0';
                        counter <= "0000";
                        curr_addr <= write_addr;
                        next_state <= WRITE_MEM;
                    end if;
                
                when WRITE_MEM =>
                    o_we <= '1';
                    o_data <= z;
                    write_addr <= write_addr +1;
                    next_state <= DISABLE_WRITING;    
                    
                when DISABLE_WRITING =>
                    o_we <= '0';
                    if(write_addr > "0000001111101000" + n_words*2-1) then 
                        next_state <= DONE;
                    elsif(counter = "0101") then
                        conv_en <= '1';
                        next_state <= CONV;
                    else
                        curr_addr <= read_addr;
                        counter <= "0000";
                        next_state <= READ;
                    end if;
                
                when DONE => 
                    o_done <= '1';
                    o_en <= '0';
                    if(i_start = '0') then 
                        o_done <= '0';
                        conv_en <= '0';
                        conv_rst <= '1';
                        next_state <= START;
                    else
                        next_state <= DONE;
                    end if;
                    
                when others => 
                    next_state <= START;
                    
            end case;
        end if;
    end process;
    
    -- CONVOLUTORE   
    conv_state_reg: process(i_clk, i_rst, conv_rst) 
        begin 
            if (rising_edge(i_clk)) then
                current_state_conv <= next_state_conv;
            end if; 
        end process;
        
    -- CONVOLUTORE    
    conv_delta_lambda: process(i_clk, i_rst, conv_rst, current_state_conv, conv_en)
    begin
        if(i_rst = '1' OR conv_rst = '1') then 
            next_state_conv <= S00;
        elsif(conv_en = '1' AND falling_edge(i_clk)) then
            case current_state_conv is
                    
                when S00 =>
                    if u = '0' then
                        next_state_conv <= S00;
                        z <= z(5 downto 0) & "00";
                    else
                        next_state_conv <= S10;
                        z <= z(5 downto 0) & "11" ;
                    end if;
                    
                when S01 =>
                    if u = '0' then
                        next_state_conv <= S00;
                        z <= z(5 downto 0) & "11";
                    else
                        next_state_conv <= S10;
                        z <= z(5 downto 0) &  "00";
                    end if;           
                         
                when S10 =>
                    if u = '0' then
                        next_state_conv <= S01;
                        z <= z(5 downto 0) & "01";
                    else
                        next_state_conv <= S11;
                        z <= z(5 downto 0) & "10";
                    end if;                
                    
                when S11 =>
                    if u = '0' then
                        next_state_conv <= S01;
                        z <= z(5 downto 0) & "10";
                    else
                        next_state_conv <= S11;
                        z <= z(5 downto 0) & "01";
                    end if;  
                    
                when others =>
                    next_state_conv <= S00;    
                      
            end case;
        end if;
    end process;
           
end Behavioral;