# DSL `Tagas`

## Descrição Resumida da DSL

> O projeto TAGAS visa a criação de uma DSL capaz de gerar/editar grafos e rodas algoritmos sobre eles de maneira prática e interativa.

> Contextualização da linguagem:
>   Grafos

> Motivação:
>   A motivação da nossa linguagem é facilitar o trabalho e a representação de grafos no ponto de vista educativo.

> Relevância:
>   Grafos são de grande importância em diversos contextos da computação, por issom vimos a necessidade de simplificar tarefas envolvendo essa estrutura de dados.

## Slides

> [Link para a apresentação (PDF).](https://drive.google.com/file/d/1SFINYwWnTV1X1fZ4e3IoRCUgkoGGQLRK/view?usp=sharing)

## Sintaxe da Linguagem na Forma de Tutorial

Um PONTO é rotulado por qualquer sequência envolvendo letras maiúsculas, dígitos ou "_". Exemplos: A1, C3, PO, PONTO_LEGAL, R2_D2, B7

Uma ARESTA é rotulada por dois pontos unidos por um sinal de '>' (aresta unidirecional) ou '<>' (aresta bidirecional / duas arestas com sentidos opostos). Exemplos: A1>C3, PONTO_LEGAL<>R2_D2

Um ENCADEAMENTO de arestas é rotulado por vários pontos unidos por sinais de arestas ('<' ou '<>'). Exemplos: A1>PO<>C3, R2_D2>C3>PO>PONTO_LEGAL>A1

Chamaremos de ELEMENTO SIMPLES qualquer sequência (única) que represente um PONTO, ARESTA ou ENCADEAMENTO simples, isto é, com as estruturas mostradas até agora, sem o uso de CONJUNTOS (que são explicados depois neste documento).

<br />

Para **criar** pontos e arestas no grafo, utilizamos o comando '**define**' seguido dos ELEMENTOS que queremos criar, separados por espaço. Exemplos:
```
define A B>C          # esta linha cria os pontos A, B e C no grafo, com uma aresta apontando de B para C.
define A>B<>C>D<>E D>A   # esta linha cria os pontos e as arestas correspondentes (ligação bidirecional entre B e C etc)
```
Para **remover**, utilizamos a mesma estrutura do 'define', só que com a palavra reservada '**remove**'.

<br />

Um CONJUNTO de pontos é uma listagem de pontos definida por colchetes com os rótulos dos pontos separados por espaço dentro. Exemplos: [PONTO1 PONTO2 PONTO3 ...], [C3 A1 B7]

Os conjuntos são uma poderosa ferramenta para a declaração de múltiplas arestas ligando pontos em comum. Substituindo um PONTO por um conjunto de pontos, declaramos arestas paralelamente entre os pontos nos conjuntos em questão.
Exemplos:
```
P1>[P2 P3 P4 ...]    # P1 apontando para P2, P3 e P4 (3 arestas sendo representadas por um único '>')
[P1 P2 P3]>P4        # P1, P2 e P3 apontando para P4
[P1 P2]>[P3 P4]      # Equivalente a:  P1>P3 P1>P4 P2>P3 P2>P4
[P1 P2]<>[P3 P4]     # Equivalente a:  P1<>P3 P1<>P4 P2<>P3 P2<>P4   ou então   P1<>P3<>P2 P1<>P4<>P2
```
Uma declaração como estas acima (que usa CONJUNTOS) é chamada de ELEMENTO PODEROSO.

ELEMENTOS PODEROSOS **podem** ser usados (apenas) nos comandos **define** e **remove**.

<br />

Comandos de paths e 'exists':

O comando '**path**' diz se existe caminho que passa (pelo menos uma vez) pelos ELEMENTOS SIMPLES especificados, ele não se importa com a ordem dos parâmetros e pode incluir outros elementos no caminho final. Já o '**path_seq**' faz quase a mesma coisa, só que ele se importa com que os elementos especificados apareçam no caminho final na mesma ordem em que foram especificados.

O comando '**exists**' é muito mais específico. Ele diz se o único ELEMENTO SIMPLES especificado existe no grafo. Este elemento simples pode ser um encadeamento, portanto o comando '**exists**' pode ser usado para confirmar a existência de um caminho exato descrito por completo em forma de encadeamento.

Demais comandos estão descritos na seção de palavras reservadas abaixo!

<br />

Labels de código: a linguagem TAGAS permite nomear linhas de código com **labels**!
O funcionamento das labels (ou consts) é muito parecido com o "#define" da linguagem C e tem a estrutura usando dois pontos (':'):
```
nome_label_arbitrario: "qualquer linha de código ou elemento que passa na gramática core da linguagem TAGAS"
```
Exemplos do uso:
```
arvore_1: A>B>C   # definição de label
conjunto_A: [A C E G]
pesquisa: path_seq B D>E F
```

<br />

**Palavras reservadas:**

define: declara N pontos ou arestas divididos por espaços.

remove: apaga N pontos ou arestas divididos por espaços.

path: recebe como parâmetro pontos ou arestas e verifica se existe uma caminho que passa pelos ELEMENTOS SIMPLES recebidos.

path_seq: recebe como parâmetro pontos ou arestas e verifica se existe uma caminho que passa pelos ELEMENTOS SIMPLES recebidos, NA ORDEM em que foram escritos.

exists: diz se UM ELEMENTO SIMPLES (ponto, aresta ou encadeamento de arestas) existe.

cycle: retorna quantos ciclos existem no grafo.

connected: retorna True se o grafo for conexo e False se não for.

print: printa o grafo.

matrix: printa o grafo na forma de matriz.

graph_line: retorna a string de uma linha "define ..." que gera o grafo atual inteiro.

undo: desfaz o último comando que alterou o grafo.


## Gramática da Linguagem

```
# gramática core

START::= define MULTIPLE_ELEMENTS | remove MULTIPLE_ELEMENTS
MULTIPLE_ELEMENTS::= ELEMENT | ELEMENT MULTIPLE_ELEMENTS
ELEMENT::= POINT | EDGES_DECLARATION
POINT::= [A-Z0-9_]+
MULTIPLE_POINTS::= POINT | POINT MULTIPLE_POINTS
EDGES_DECLARATION::= SET>SET | SET<>SET | C>EDGES_DECLARATION | C<>EDGES_DECLARATION
SET::= POINT | [POINT MULTIPLE_POINTS]
START::= path POINT MULTIPLE_PATH_ARGS
START::= path_seq POINT MULTIPLE_PATH_ARGS
START::= exists PATH_ARG
MULTIPLE_PATH_ARGS::= PATH_ARGS | PATH_ARGS MULTIPLE_PATH_ARGS
PATH_ARG::= POINT | POINT>POINT | POINT<>POINT | POINT>PATH_ARG | POINT<>PATH_ARG
START::= matrix | print | cycle | connected | graph_line | undo



# pré checagem por declaração de constante (inicia em CONST)

CONST::= LABEL: START | LABEL: MULTIPLE_ELEMENTS
LABEL = [a-z0-9_]+ (exceto palavras reservadas)
(... core)
```


## Exemplos Selecionados

As linhas com " > " representam um possivel output instantâneo de um programa rodando a linguagem TAGAS

- **Exemplo 1**
```
define A1 A2 A3
define A1>A2 A2>A3
cycle
  > 0
define A3>A1
cycle
  > 1
define A2>A1
cycle
  > 2
```

- **Exemplo 2**
```
define A1 A2 A3 A4
define A1>A2 A2>A3
connected
  > False
define A1>A4
connected
  > True
```

- **Exemplo 3**
```
define A1 B2 C3
define A1>B2 B2>C3
graph
matrix
```

- **Exemplo 4**
```
define A1 A2 A3 A4
define A1>A2 A2>A3 A3>A4
path A1 A4 A2>A3
    > True
path_seq A1 A4 A2>A3
    > False
path_seq A1 A2>A3 A4
    > True
```

- **Exemplo 5**
```
define A1 A2 A3
define A1>A2 A2>A3
define A4 A3>A4
graph_line
    > "define A1>A2>A3>A4"
exists A4
    > True
undo
graph_line
    > "define A1>A2>A3"
exists A4
    > False
```

- **Exemplo 6**
```
arvore_1: A>B>C   # definição de label
define D E<>F arvore_1
exists arvore_1
  > True
remove B>C
exists arvore_1
  > False
```

- **Exemplo 7**
```
filhos: [MIKE DUSTIN LUCAS WILL]   # definição de label
define PAI>filhos
exists PAI>LUCAS
  > True
define MAE>filhos
remove PAI>filhos
```

# Referências Bibliográficas

Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, and Cliﬀord Stein. Introduction to Algorithms. MIT Press, 4th edition, 2022.

SANTOS, Rodrigo Pereira dos; COSTA, Heitor Augustus Xavier. Um software gráfico educacional para o ensino de algoritmos em grafos. Lavras: UFLA, 2006.

GRAPHVIZ, disponível em [https://graphviz.org/](https://graphviz.org/)
