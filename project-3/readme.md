# DSL Tagas

## Descrição Resumida da DSL

A **Tagas** é uma DSL (Linguagem de Domínio Específico) criada para facilitar a vida de quem estuda ou trabalha com grafos. Muitas vezes, para criar um grafo simples e rodar testes em linguagens tradicionais, é preciso escrever muito código de configuração (*boilerplate*). A proposta da Tagas é resolver isso, permitindo gerar, editar e analisar grafos de forma prática, rápida e interativa.

A nossa linguagem usa uma arquitetura mista: a interface e a leitura dos comandos são feitas em **Python**, mas toda a mágica de manipulação do grafo e armazenamento acontece por trás dos panos em **Scheme (usando o ambiente Racket)**, aproveitando o poder do paradigma funcional para gerenciar os dados.

A principal motivação do projeto é o ambiente educativo. Como a Teoria dos Grafos é uma matéria complexa e fundamental na computação, vimos a relevância de criar uma ferramenta onde o estudante possa focar no conceito — como checar se há ciclos, caminhos ou se o grafo é conexo — sem perder tempo brigando com estruturas de dados complicadas. Com comandos simples e intuitivos, a Tagas transforma linhas de texto em estruturas prontas para testes.

## Slides

[Link para o PDF da Apresentação Final](https://drive.google.com/file/d/1SFINYwWnTV1X1fZ4e3IoRCUgkoGGQLRK/view?usp=sharing)

## Sintaxe da Linguagem

Um **VÉRTICE** é rotulado por qualquer sequência envolvendo letras maiúsculas, dígitos ou "_". Exemplos: `A1`, `C3`, `PO`, `VERTICE_LEGAL`, `R2_D2`, `B7`.

Uma **ARESTA** é rotulada por dois vértices unidos por um sinal de `>` (aresta unidirecional) ou `<>` (aresta bidirecional / duas arestas com sentidos opostos). Exemplos: `A1>C3`, `VERTICE_LEGAL<>R2_D2`.

Um **ENCADEAMENTO** de arestas é rotulado por vários vértices unidos por sinais de arestas (`>` ou `<>`). Exemplos: `A1>PO<>C3`, `R2_D2>C3>PO>VERTICE_LEGAL>A1`.

Chamaremos de **ELEMENTO SIMPLES** qualquer sequência única que represente um VÉRTICE, ARESTA ou ENCADEAMENTO simples, ou seja, estruturado sem o uso de conjuntos.

---

Para **criar** vértices e arestas no grafo, utilizamos o comando `add` seguido dos elementos que queremos criar, separados por espaço. Exemplos:

add A B>C         # Cria os vértices A, B e C, com uma aresta apontando de B para C.
add A>B<>C>D<>E D>A  # Cria os vértices e as arestas correspondentes (ligação bidirecional entre B e C etc.)

Para **remover**, utilizamos a mesma estrutura do `add`, mas com a palavra reservada `remove`.

---

Um **CONJUNTO** de vértices é uma lista definida por colchetes com os rótulos dos vértices separados por espaço. Exemplos: `[VERTICE1 VERTICE2 VERTICE3]`, `[C3 A1 B7]`.

Os conjuntos ajudam a declarar múltiplas arestas ligando vértices em comum de uma só vez. Substituindo um vértice por um conjunto, declaramos arestas paralelamente entre todos os vértices envolvidos. Exemplos:
V1>[V2 V3 V4]     # V1 apontando para V2, V3 e V4 (3 arestas representadas por um único '>')
[V1 V2 V3]>V4     # V1, V2 e V3 apontando para V4
[V1 V2]>[V3 V4]   # Equivalente a: V1>V3 V1>V4 V2>V3 V2>V4
[V1 V2]<>[V3 V4]  # Equivalente a: V1<>V3 V1<>V4 V2<>V3 V2<>V4

Uma declaração que usa conjuntos é chamada de **ELEMENTO PODEROSO**. Eles só podem ser usados dentro dos comandos `add` e `remove`.

---

### Comandos de Caminhos (Paths) e Existência

* **`path`**: Verifica se existe um caminho que vai de um vértice A até um B e retorna uma lista com o caminho, caso encontrado.
* **`path-seq`**: Verifica se existe um caminho que passe por todos os n elementos especificados **na mesma ordem** em que foram escritos no comando. Também retorna um lista com o caminho encontrado.

---

### Labels (Rótulos de Código)
A Tagas permite nomear linhas de código com **labels** (similar ao `#define` do C), facilitando a reutilização de estruturas usando dois pontos (`:`):
nome_label: "qualquer linha de código ou elemento válido na gramática da Tagas"

Exemplos de uso:
subgrafo_1: A>B>C
conjunto_A: [A C E G]
pesquisa: path-seq B D>E F

---

### Palavras Reservadas

* **`add`**: Declara N vértices ou arestas separados por espaços.
* **`remove`**: Apaga N vértices ou arestas separados por espaços.
* **`path`**: Verifica se existe um caminho passando pelos elementos informados.
* **`path-seq`**: Verifica se existe um caminho passando pelos elementos informados na ordem exata.
* **`print`**: Exibe a estrutura atual do grafo.
* **`undo`**: Desfaz o último comando que alterou o grafo.
* **`exit`**: Fecha o terminal ativo.

## Gramática da Linguagem

START ::= add MULTIPLE_ELEMENTS | remove MULTIPLE_ELEMENTS
MULTIPLE_ELEMENTS ::= ELEMENT | ELEMENT MULTIPLE_ELEMENTS
ELEMENT ::= VERTEX | EDGES_DECLARATION
VERTEX ::= [A-Z0-9_]+
MULTIPLE_VERTICES ::= VERTEX | VERTEX MULTIPLE_VERTICES
EDGES_DECLARATION ::= SET>SET | SET<>SET | SET>EDGES_DECLARATION | SET<>EDGES_DECLARATION
SET ::= VERTEX | [VERTEX MULTIPLE_VERTICES]

START ::= path VERTEX MULTIPLE_PATH_ARGS
START ::= path_seq VERTEX MULTIPLE_PATH_ARGS
MULTIPLE_PATH_ARGS ::= PATH_ARGS | PATH_ARGS MULTIPLE_PATH_ARGS
PATH_ARG ::= VERTEX | VERTEX>VERTEX | VERTEX<>VERTEX | VERTEX>PATH_ARG | VERTEX<>PATH_ARG

START ::= print | undo | exit

# Pré-checagem por declaração de constante (Labels)

CONST ::= LABEL: START | LABEL: MULTIPLE_ELEMENTS
LABEL ::= [a-z0-9_]+ (exceto palavras reservadas)

---

## Notebook

Para abrir o terminal é necessário rodar o programa em Python [tagas_terminal](tagas_terminal.py) e ter a biblioteca Racket instalada para rodar o scheme no backgroud.

Markdown
## Exemplos Selecionados

As linhas iniciadas com `->` representam o retorno gerado pelo interpretador da Tagas após a execução do comando que é iniciado com `#`.

### Exemplo 1: Caminhos Simples (`path`) vs. Caminhos Sequenciais (`path_seq`)
```
# add A1 A2 A3 A4
# add A1>A2 A2>A3 A3>A4
# path A1 A4 A2>A3
-> True
# path_seq A1 A4 A2>A3
-> False
# path_seq A1 A2>A3 A4
>True
```

### Exemplo 2: Histórico com `undo` e Exportação com `print`
```
# add A>B<>C
# print
-> ((C B) (B C) (A B))
# add A>C
# print
-> ((C B) (B C) (A B C))
# undo
-> Última ALTERAÇÂO do grafo DESFEITA!
# print
-> ((C B) (B C) (A B))
```

### Exemplo 3: Uso de Labels (Constantes) e remoção com `remove`
```
# arvore_1: A>B>C   # Definição do label
# add D E<>F arvore_1
# print
-> ((D) (E F) (F E) (A B) (B C))
# remove B>C
# print
-> ((D) (E F) (F E) (A B))
```

### Exemplo 4: Operações Avançadas com Conjuntos (Elementos Poderosos) e Labels
```
# filhos: [MIKE DUSTIN LUCAS WILL]   # Definição do label contendo um conjunto
# add PAI>filhos
# path PAI>LUCAS
-> True
# add MAE>filhos
# remove PAI>filhos
# exit
-> Comando EXIT recebido.
```
## Discussão

A Tagas conseguiu cumprir com sucesso o objetivo proposto de ser uma ferramenta prática e direta para a criação e manipulação de grafos. Quando o usuário se acostuma com a gramática básica, a velocidade para montar um grafo complexo e testar suas propriedades é visivelmente maior do que se estivesse escrevendo código em uma linguagem tradicional.

Porém, por ser um projeto de escopo acadêmico, o grupo identificou algumas limitações. O sistema não foi testado por usuários externos, ficando restrito às validações feitas pelos próprios desenvolvedores. Além disso, a linguagem atualmente lida apenas com grafos simples e não-valorados (ou seja, sem pesos nas arestas ou propriedades customizadas nos vértices), restringindo um pouco o tipo de problema que pode ser modelado nela hoje.

## Conclusão

O desenvolvimento da Tagas trouxe grandes aprendizados para o grupo, principalmente ao nos forçar a integrar duas tecnologias muito diferentes: o **Python** (lidando com a interface e o parser da gramática) e o **Scheme via Racket** (gerenciando a estrutura interna do grafo através do paradigma funcional). Pensar em grafos usando listas indexadas e recursão em Scheme foi uma excelente quebra de paradigma.

O maior desafio técnico do projeto foi implementar a remoção de elementos (`remove`). Enquanto adicionar elementos aceita praticamente qualquer ordem sem quebrar a estrutura, a remoção exige muito mais cuidado, pois apagar um vértice ou uma aresta pode desestruturar encadeamentos e gerar comportamentos inesperados se a ordem dos fatores não for bem pensada pelo interpretador.

## Trabalhos Futuros

Se o projeto tivesse mais tempo de desenvolvimento, focaríamos nas seguintes melhorias:
1. **Evolução dos Elementos Poderosos**: Dar maior suporte e flexibilidade para operações complexas envolvendo conjuntos.
2. **Propriedades Avançadas**: Permitir que tanto os vértices quanto as arestas aceitem pesos e propriedades customizadas, possibilitando a criação de grafos de conhecimento muito mais ricos.
3. **Aprimoramento do `graph_line`**: Aperfeiçoar a função que gera a string do grafo inteiro para que ela sempre devolva a forma mais otimizada e limpa possível para recriar o grafo com um único comando `add`.
4. **Visualização Gráfica**: Integrar o motor à ferramentas de renderização (como o Graphviz) diretamente no ambiente do Notebook para exibir o grafo de forma visual e em tempo real.

# Referências Bibliográficas

Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, and Cliﬀord Stein. Introduction to Algorithms. MIT Press, 4th edition, 2022.

SANTOS, Rodrigo Pereira dos; COSTA, Heitor Augustus Xavier. Um software gráfico educacional para o ensino de algoritmos em grafos. Lavras: UFLA, 2006.

GRAPHVIZ, disponível em [https://graphviz.org/](https://graphviz.org/)
