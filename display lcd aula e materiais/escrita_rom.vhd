library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is 
    port(
        i_clk, i_miso, i_ena, i_reset : in std_logic;
        o_cs, o_sck, o_mosi, o_dc : out std_logic;
        o_leds : out std_logic_vector(7 downto 0);
        mem_addr : out std_logic_vector(12 downto 0);
        mem_data : in std_logic_vector(17 downto 0)
    );
end entity;

architecture rtl of display is

    type t_commands is array (natural range<>) of std_logic_vector(8 downto 0);
	constant sequencia_de_comandos : t_commands (9 downto 0) := (
        "000010001", -- sleep out
        "000010011", -- normal mode on
        "000100000", -- inversion off
        "001010001", -- brightness
        "111111111", -- max brightness
        "000100110", -- gama
        "100000001", -- curva de gama 1
        "000111010", -- formato de pixel
        "101100110", -- formato 18 bits
        "000101001"); -- display on

    type estados is (parado, comando, comando_escrever, pixels);
    signal estado_atual, proximo_estado : estados := parado;

    signal coluna, deslocamento_coluna : integer range 0 to 320 := 0;
    signal linha, deslocamento_linha : integer range 0 to 320 := 0;
    signal pixel : integer range 0 to 24 := 0;

    signal sck_enable : std_logic := '0';

    signal R, G, B : std_logic_vector(5 downto 0);
    signal RGB : std_logic_vector (0 to 23);

    constant constante_comando_escrever : std_logic_vector (7 downto 0) := "00101100";
    -- usando o cyclone II voce pode colocar duas imagens 80x60, entao a escala e 4
    constant escala : integer := 4;
begin    
    o_sck <= i_clk when sck_enable = '1' else '0';
    RGB <= R & "11" & G & "11" & B & "11";

    R <= mem_data(17 downto 12);
    G <= mem_data(11 downto 6);
    B <= mem_data(5 downto 0);
    mem_addr <= std_logic_vector(to_unsigned(((240/escala) * (linha/escala)) + (coluna/escala), 13)); 

    passador_maquina : process(i_clk, estado_atual, proximo_estado)
    begin
        if rising_edge(i_clk) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    comandos : process(i_clk, estado_atual, linha, coluna, pixel, i_miso) 
        variable contagem_bits : integer range 7 downto 0;
        variable contagem_comandos : integer range 0 to sequencia_de_comandos'length; 
        variable comando_enviar : std_logic_vector (8 downto 0);
    begin
        if falling_edge(i_clk) then
            case estado_atual is
            when parado =>
                o_mosi <= '0';
                o_leds <= not "00000000";
                o_dc <= '0';
                o_cs <= '1';
                sck_enable <= '0';

                contagem_bits := 7;
                contagem_comandos := sequencia_de_comandos'length - 1;

                pixel <= 0;
                coluna <= 0;
                linha <= 0;

                if i_ena = '0' then
                    proximo_estado <= comando;
                end if;

            when comando =>
                o_cs <= '0';
                sck_enable <= '1';
                o_mosi <= comando_enviar(contagem_bits);
                comando_enviar := sequencia_de_comandos(contagem_comandos);
                if comando_enviar(8) = '1' then
                    o_dc <= '1';
                else
                    o_dc <= '0';
                end if;

                if contagem_bits > 0 then
                    contagem_bits := contagem_bits - 1;
                else
                    contagem_bits := 7;
                    if contagem_comandos > 0 then
                        contagem_comandos := contagem_comandos - 1;
                    else
                        proximo_estado <=  comando_escrever;
                    end if;
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

                if pixel = 23 then
                    pixel <= 0;
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
                    pixel <= pixel + 1;
                end if;
            end case;
        end if;
    end process;
end rtl;