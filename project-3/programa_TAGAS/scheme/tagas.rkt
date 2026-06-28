(display "Carregando tagas.rkt\n")


; base do grafo (compartilhada entre os membros do grupo do projeto TAGAS)

(define graph-schema
    '((directed . 0) (weighted . 1) (direct-loop . 2) (body . 3))
)

(define (getp g p)
    (list-ref g (cdr (assq p graph-schema)))
)

(define (replace-by-i i value l)
    (if (= i 0)
        (cons value (cdr l))
        (cons (car l) (replace-by-i (- i 1) value (cdr l)))
    )
)

(define (setp g p value)
    (replace-by-i (cdr (assq p graph-schema)) value g)
)


;; funções para o comando add

(define (add-vertex grafo v)
    (let ((body (getp grafo 'body)))
        (if (assq v body)
            grafo
            (setp grafo 'body (cons `(,v . ()) body))
        )
    )
)

(define (add-vertexs grafo . vertexs)
    (if (null? vertexs)
        grafo
        (apply add-vertexs `(,(add-vertex grafo (car vertexs)) ,@(cdr vertexs)))
    )
)

(define (replace-by-key key value l)
    (cond
        ((null? l)
            l)
        ((eq? (car (car l)) key)
            (cons `(,key . ,value) (cdr l)))
        (else (cons (car l)
            (replace-by-key key value (cdr l))))
    )
)

; apenas adiciona v2 na lista de adjacências de v1, sem se preocupar com o tipo do grafo
; e sem checar a existência de v1 e v2 antes (dá erro se v1 não existir)
(define (add-adjacency grafo v1 v2)
    (let ((body (getp grafo 'body)))
        (let ((v1-edges (cdr (assq v1 body))))
            (if (memq v2 v1-edges)
                grafo
                (setp grafo 'body (replace-by-key v1 (cons v2 v1-edges) body))
            )
        )
    )
)

; adiciona a aresta entre v1 e v2, checando o tipo do grafo
; se for não direcionado adiciona a adjacência v1-v2 e v2-v1
; cria os vértices v1 e/ou v2 caso não existam
(define (add-edge grafo v1 v2)
    (let ((body (getp grafo 'body)))
        (if (assq v1 body)
            (if (assq v2 body)
                (if (getp grafo 'directed)
                    (add-adjacency grafo v1 v2)
                    (add-adjacency (add-adjacency grafo v1 v2) v2 v1)
                )
                (add-edge (add-vertex grafo v2) v1 v2)
            )
            (add-edge (add-vertex grafo v1) v1 v2)
        )
    )
)

; Função mais próxima do 'add', serve para criar vértices e arestas no grafo: add A>B B>C D>A
; se limitando somente pares
; exemplo: (add-edges grafo (A B) (B C) (C A))
(define (add-edges grafo . edges)
    (if (null? edges)
        grafo
                ;   (add-edges grafo . (cdr edges))
        (apply add-edges `(,(apply add-edge (list grafo (car (car edges)) (cadr (car edges)))) ,@(cdr edges)))
    )
)





; running logic

; (directed   (not) weighted   (not) direct-loop   body)
(define GRAFO '(#t #f #f ()))

(define (print)
    (display (getp GRAFO 'body))
)
(define (add-vertex! V)
    (set! GRAFO (add-vertex GRAFO V))
)
(define (add-vertexs! . vertexs)
    (set! GRAFO (apply add-vertexs `(,GRAFO ,@vertexs)))
)
(define (add-edge! V1 V2)
    (set! GRAFO (add-edge GRAFO V1 V2))
)
(define (add-edges! . edges)
    (set! GRAFO (apply add-edges `(,GRAFO ,@edges)))
)

(display "tagas.rkt CARREGADO até o final!  :D\n")





; TAGAS syntax

(define-syntax add
    ;; Declaramos o '<>' como uma palavra-chave oficial junto com o '>'
    (syntax-rules (> <>)
        ;; 1. Casos base de parada da recursão
        [ (add) (void) ]

        ;; 2. PADRÃO: Unidirecional (>)   ex: (add A > B)
        [ (add origem > destino resto ...)
            (begin
                (display "Criando aresta de ida!") (newline)
                (add-edge! 'origem 'destino)
                ;; Chama a macro de novo para processar o restante da linha
                (add resto ...)
            )
        ]

        ;; 3. PADRÃO: Bidirecional (<>)   ex: (add A <> B)
        [ (add origem <> destino resto ...)
            (begin
                (display "Criando aresta de ida e volta!") (newline)
                (add-edge! 'origem 'destino)
                (add-edge! 'destino 'origem)
                ;; Chama a macro de novo para processar o restante da linha
                (add resto ...)
            )
        ]

        ;; 4. PADRÃO: Criar vértice apenas   ex: (add A)
        [ (add vertice resto ...)
            (begin
                (display "Criando vértice!") (newline)
                (add-vertex! 'vertice)
                ;; Continua processando o resto da linha
                (add resto ...)
            )
        ]
    )
)
