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

; usado pela macro que relaciona diretamente o comando add da TAGAS
(define (add-vertex grafo v)
    (let ((body (getp grafo 'body)))
        (if (assq v body)
            grafo
            (setp grafo 'body (cons `(,v . ()) body))
        )
    )
)

; possível utility - não está sendo usada pelas macros
(define (add-vertexs grafo . vertexs)
    (if (null? vertexs)
        grafo
        (apply add-vertexs `(,(add-vertex grafo (car vertexs)) ,@(cdr vertexs)))
    )
)

; utility
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

; utility
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
; usado pela macro que relaciona diretamente o comando add da TAGAS
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
; possível utility - não está sendo usada pelas macros
(define (add-edges grafo . edges)
    (if (null? edges)
        grafo
                ;   (add-edges grafo . (cdr edges))
        (apply add-edges `(,(apply add-edge (list grafo (car (car edges)) (cadr (car edges)))) ,@(cdr edges)))
    )
)

(display "Biblioteca TAGAS carregada...\n")



; running logic

; definição de estado inicial do grafo para a TAGAS
; (directed   (not) weighted   (not) direct-loop   body)
(define GRAFO '(#t #f #f ()))
(define HISTORICO '())

; Salva o estado atual do grafo no histórico, concretizando uma alteração do grafo
(define (GRAFO-to-historic!)
    (set! HISTORICO (cons GRAFO HISTORICO))
)

; Desfaz a última alteração do grafo, restaurando o estado anterior do grafo no histórico
(define (undo!)
    (if (null? HISTORICO)
        (display "[WARNING] Não há histórico para desfazer.")
        (begin
            (set! GRAFO (car HISTORICO))
            (set! HISTORICO (cdr HISTORICO))
            (display "Última ALTERAÇÃO do grafo DESFEITA com sucesso!\n")
        )
    )
)

; print direto da TAGAS
(define (print)
    (display (getp GRAFO 'body))
)

; usado pela macro que relaciona diretamente o comando add da TAGAS
(define (add-vertex! V)
    (set! GRAFO (add-vertex GRAFO V))
)
; usado pela macro que relaciona diretamente o comando add da TAGAS
(define (add-edge! V1 V2)
    (set! GRAFO (add-edge GRAFO V1 V2))
)

; possível utility - não está sendo usada pelas macros
(define (add-vertexs! . vertexs)
    (set! GRAFO (apply add-vertexs `(,GRAFO ,@vertexs)))
)
; possível utility - não está sendo usada pelas macros
(define (add-edges! . edges)
    (set! GRAFO (apply add-edges `(,GRAFO ,@edges)))
)

(display "Lógica de runtime TAGAS carregada...\n")



; TAGAS syntax

(define-syntax execute
  ;; Declaramos TODOS os comandos oficiais da TAGAS aqui
  (syntax-rules (add print undo)
    
    ;; ---------------------------------------------------------
    ;; Comandos Mutáveis (Precisam salvar histórico)
    [ (execute add args ...)
      (begin
        (GRAFO-to-historic!)
        (add args ...)
        
      )
    ]
    ;;; [ (execute remove args ...)
    ;;;   (begin
    ;;;     (GRAFO-to-historic!)
    ;;;     (remove args ...) ; Supondo que você crie esse comando depois
    ;;;   )
    ;;; ]

    ;; ---------------------------------------------------------
    ;; Comandos Read-Only (Não sujam o histórico)
    [ (execute print)
      (print)
    ]
    [ (execute undo)
      (undo!)
    ]

    ;; ---------------------------------------------------------
    ;; Tratamento de erro (comando inexistente)
    [ (execute print useless_args ...)
      (display "[ERRO] O comando 'print' não aceita argumentos.")
    ]
    [ (execute undo useless_args ...)
      (display "[ERRO] O comando 'undo' não aceita argumentos.")
    ]
    [ (execute unknown_word args ...)
      (begin
        (display "[ERRO] O comando '") (display 'unknown_word) 
        (display "' não existe.\n")
      )
    ]
  )
)

(define-syntax add
    ;; Declaramos o '<>' como uma palavra-chave oficial junto com o '>'
    (syntax-rules (> <>)
        ;; 1. Casos base de parada da recursão
        [ (add) (void) ]

        ;; ERRO: checagem de sobra de operador
        [ (add > resto ...) (display "[Warning] Operador '>' sobrando não causou efeito.\n") ]
        [ (add <> resto ...) (display "[Warning] Operador '<>' sobrando não causou efeito.\n") ]

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


(display "Macros de syntax TAGAS carregadas...\n")
(display "tagas.rkt CARREGADO até o final!  :D\n")