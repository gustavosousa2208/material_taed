
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is 
    generic (constant n_divisor : integer := 10);
    port(
        i_clk, i_miso, i_ena, i_reset : in std_logic;
        o_cs, o_sck, o_mosi, o_dc : out std_logic;
        o_leds : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of display is

    type t_commands is array (natural range<>) of std_logic_vector(8 downto 0);
    constant sequencia_inicializar : t_commands (12 downto 0) := ("000010001", 
    "000010011", 
    "000100000", 
    "001010001", "101111111", 
    "000100110", "100000001", 
    "000111010", "101100110", 
    "000110111", "100000000", "100000000", 
    "000101001");

    type estados is (parado, comando, comando_escrever, pixels);
    signal estado_atual, proximo_estado : estados := parado;

    signal div_clk : std_logic := '0';
    signal sck_enable : std_logic := '0';

    signal coluna, columnOffset : integer range 0 to 320 := 0;
    signal linha, lineOffset : integer range 0 to 320 := 0;
    signal pixel : integer range 0 to 24 := 0;

    signal R, G, B : std_logic_vector(5 downto 0);
    signal RGB : std_logic_vector (23 downto 0);

    constant constante_comando_escrever : std_logic_vector (7 downto 0) := "00101100";
begin    

    o_sck <= div_clk when sck_enable = '1' else '0';
    RGB <= R & "11" & G & "11" & B & "11";
    
    maquina_de_estados : process(i_clk,estado_atual, proximo_estado)
    begin
        if rising_edge(i_clk) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    divisao_de_clock : process(i_clk)
        variable conta : integer := 0;
    begin
        if rising_edge(i_clk) then
            if conta = n_divisor then
                conta := 0;
                div_clk <= not div_clk;
            else 
                conta := conta + 1;
            end if;
        end if;
    end process;

    desenhar : process(linha, coluna, lineOffset, columnOffset, div_clk, pixel)
        variable conta_tempo : integer := 0;
        variable conta_coluna : integer := 0;
    begin
        if falling_edge(div_clk) then
            if conta_tempo < 5e6 then
                conta_tempo := conta_tempo + 1;
            else
                conta_tempo := 0;
                if conta_coluna < 319 then
                    conta_coluna := conta_coluna + 20;
                else
                conta_coluna := 0;
                end if;
            end if;

            if (linha > conta_coluna) and (linha < conta_coluna + 20) then
                R <= "111111";
                G <= "000000";
                B <= "000000";
            else
                R <= "000000";
                G <= "000000";
                B <= "000000";
            end if;
        end if;
    end process;

    enviar_comandos_pixels : process(div_clk, estado_atual, linha, coluna, pixel, i_miso) 
        variable contagem_bits : integer range 15 downto 0;
        variable contagem_comandos : integer range 0 to sequencia_inicializar'length; 
        variable comando_enviar : std_logic_vector (7 downto 0);
    begin
        if falling_edge(div_clk) then
            case estado_atual is
            when parado =>
                o_mosi <= '0';
                o_leds <= not "00000000";
                o_dc <= '0';
                o_cs <= '1';
                sck_enable <= '0';

                contagem_bits := 7;
                contagem_comandos := sequencia_inicializar'length - 1;

                pixel <= 23;
                coluna <= 0;
                linha <= 0;

                if i_ena = '0' then
                    proximo_estado <=  comando;
                end if;

            when comando =>
                o_cs <= '0';
                o_mosi <= comando_enviar(contagem_bits);
                sck_enable <= '1';
                comando_enviar := sequencia_inicializar(contagem_comandos)(7 downto 0);
                
                if sequencia_inicializar(contagem_comandos)(8) = '1' then
                    o_dc <= '1';
                else
                    o_dc <= '0';
                end if;
                
                if contagem_bits > 0 then
                    contagem_bits := contagem_bits - 1;
                else
                    if contagem_comandos > 0 then
                        contagem_comandos := contagem_comandos - 1;
                    else
                        proximo_estado <=  comando_escrever;
                    end if;

                    contagem_bits := 7;
                end if;
            when comando_escrever =>
                o_dc <= '0';
                o_cs <= '0';
                sck_enable <= '1';
                o_mosi <= constante_comando_escrever(contagem_bits);

                if contagem_bits > 0 then
                    contagem_bits := contagem_bits - 1;
                else
                    contagem_bits := 7;
                    proximo_estado <=  pixels;
                end if;
            when pixels =>
                sck_enable <= '1';
                o_dc <= '1';
                o_cs <= '0';

                o_mosi <= RGB(pixel);
                if pixel = 0 then
                    pixel <= 23;
                    if coluna = 239 then
                        coluna <= 0;
                        if linha = 319 then
                            linha <= 0;
                            proximo_estado <=  comando_escrever;
                        else
                            linha <= linha + 1;
                        end if;
                    else
                        coluna <= coluna + 1;
                    end if;
                else
                    pixel <= pixel - 1;
                end if;
            end case;
        end if;
    end process;
end rtl;

