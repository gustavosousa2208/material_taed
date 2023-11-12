Sobre as imagens, apenas formato .png ou .jpg, se for alguma coisa diferente, procure um conversor de imagem online e converta para .png. Não é necessário redimensionar, mas o que você puder fazer para deixar na resolução de 320x240 ou a resolução exata do kit (80x60) evita perda de informações; Além disso, 

Caso você não saiba o que é python, é uma linguagem de programação, 
tudo em python é mais simples, apesar de não ser a mais eficiente 
e ideal para tudo. Se não tiver, pode rodar o instalador aqui.

Escolha "Use admin privileges when installing py.exe"
e também escolha "Add python.exe to PATH". Clique em "Install Now".

Com isso já podemos rodar. Coloque as imagens na mesma pasta do 
conversor.py, clique duas vezes e uma tela surge. Você pode escolher
como quer a imagem, tem algumas resoluções, e lembre que a maior 
não cabe num kit Cyclone 2. Mas os valores padrões já estão assim
que você abrir o programa. Clique em OK depois de escolher e o
arquivo .mif estará pronto.

Se aparecer um terminal esquisito com letras vermelhas, não se 
preocupe, ele estará instalando dependências.

Em resumo, instalar o python, rodar o conversor.py e pronto, 
temos as imagens convertidas para .mif.

A saída do .mif é RGB, seis bits de cor mais 2 de dummy bytes.
Ex.: RRRRRRXX GGGGGGXX BBBBBBXX
Se lê do MSB para LSB.

Em caso de dúvida, contate: gustavosousa@alu.ufc.br
