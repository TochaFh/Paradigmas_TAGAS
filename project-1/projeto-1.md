# DSL `Tagas`

## Descrição Resumida da DSL

> Descrição resumida do tema do projeto.

> Contextualização da linguagem
    Grafos

> Motivação
    A motivação da nossa linguagem é facilitar o trabalho e a representação de grafos.

> Relevância
    Grafos são de grande importância em diversos contextos da computação, por issom vimos a necessidade de simplificar tarefas envolvendo essa estrutura de dados.

## Slides

> Coloque aqui o link para o PDF da apresentação.

## Sintaxe da Linguagem na Forma de Tutorial

> Formato: 
    pontos: letras maiúsculas, números ou "_'
    arestas: PONTO1>PONTO2 (aresta unidirecional) ou PONTO1<>PONTO2 (aresta bidirecional)

> Palavras reservadas:
    define: declara N pontos ou arestas divididos por espaços.
    remove: apaga N pontos ou arestas divididos por espaços.
    path: recebe como parâmetro pontos ou arestas e verifica se existe uma caminho que passa pelos elementos recebidos.
    cycle: retorna quantos ciclos existem no grafo.
    conncted: retorna True se o grafo for conexo e False se não for.
    graph: printa o grafo.
    matrix: printa o grafo na forma de matriz.


## Gramática da Linguagem

> S::= define O | remove O
> O::= P | A
> P::= p | p P
> A::= p>p | p<>p | p>p A | p<>p A
> S::= path p B
> B::= O | O B
> S::= matrix | graph | cycle | connected



## Exemplos Selecionados

> Exemplo 1
define A1 A2 A3
define A1>A2 A2>A3
cycle
    0
define A3>A1
cycle
    1
define A2>A1
cycle
    2

> Exemplo 2
define A1 A2 A3 A4
define A1>A2 A2>A3
connected
    False
define A1>A4
connected
    True

Exemplo 3
define A1 B2 C3
define A1>B2 B2>C3
graph
matrix


# Referências Bibliográficas

>Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, and Cliﬀord Stein. Introduction to Algorithms. MIT Press, 4th edition, 2022.

