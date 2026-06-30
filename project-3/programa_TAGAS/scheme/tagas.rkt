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


;; ---------------------------------------------------------------
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

;;; ; possível utility - não está sendo usada pelas macros
;;; (define (add-vertexs grafo . vertexs)
;;;     (if (null? vertexs)
;;;         grafo
;;;         (apply add-vertexs `(,(add-vertex grafo (car vertexs)) ,@(cdr vertexs)))
;;;     )
;;; )

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
; e sem checar a existência dos vértices v1 e v2 antes (dá erro se v1 não existir)
; se a aresta já existir, não faz nada (apenas retorna o mesmo grafo sem alterações)
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

;;; ; Função mais próxima do 'add', serve para criar vértices e arestas no grafo: add A>B B>C D>A
;;; ; se limitando somente pares
;;; ; exemplo: (add-edges grafo (A B) (B C) (C A))
;;; ; possível utility - não está sendo usada pelas macros
;;; (define (add-edges grafo . edges)
;;;     (if (null? edges)
;;;         grafo
;;;                 ;   (add-edges grafo . (cdr edges))
;;;         (apply add-edges `(,(apply add-edge (list grafo (car (car edges)) (cadr (car edges)))) ,@(cdr edges)))
;;;     )
;;; )


;; ---------------------------------------------------------------
;; funções para o comando remove

; Remove todas as ocorrências de um elemento 'x' de uma lista simples 'lst'
(define (remove-elemento x lst)
  (cond
    ((null? lst) '())
    ((eq? x (car lst)) (remove-elemento x (cdr lst)))
    (else (cons (car lst) (remove-elemento x (cdr lst))))))


;; Lógica de remoção de arestas e vértices

; Recebe o corpo do grafo e retorna um novo corpo sem o vértice 'v'
(define (remove-vertice-do-corpo corpo v)
  (cond
    ((null? corpo) '())
    (else
     (let ((linha-atual (car corpo)))
       (let ((vertice-dono (car linha-atual))
             (conexoes (cdr linha-atual)))
         
         (if (eq? vertice-dono v)
             (remove-vertice-do-corpo (cdr corpo) v)
             (cons (cons vertice-dono (remove-elemento v conexoes))
                   (remove-vertice-do-corpo (cdr corpo) v))))))))

; Recebe o corpo do grafo e retorna um novo corpo sem a aresta
(define (remove-aresta-do-corpo corpo aresta direcionado?)
  (let ((u (car aresta))   
        (v (cadr aresta))) 
    
    (define (processa-corpo c)
      (cond
        ((null? c) '())
        (else
         (let ((linha (car c)))
           (let ((vertice-dono (car linha))
                 (conexoes (cdr linha)))
             
             (cond
               ((eq? vertice-dono u)
                (cons (cons vertice-dono (remove-elemento v conexoes))
                      (processa-corpo (cdr c))))
               
               ((and (not direcionado?) (eq? vertice-dono v))
                (cons (cons vertice-dono (remove-elemento u conexoes))
                      (processa-corpo (cdr c))))
               
               (else
                (cons linha (processa-corpo (cdr c))))))))))
    
    (processa-corpo corpo)))


; usado pela macro que relaciona diretamente o comando remove da TAGAS
(define (remove-vertice g v)
  (setp g 'body (remove-vertice-do-corpo (getp g 'body) v)))

; usado pela macro que relaciona diretamente o comando remove da TAGAS
(define (remove-aresta g aresta)
  (setp g 'body (remove-aresta-do-corpo (getp g 'body) aresta (getp g 'directed))))


;;; ; Função principal que o "usuário" vai chamar.
;;; (define (remove-do-grafo g . elementos)
;;;     ; Função auxiliar com recursão de cauda para processar a lista de elementos
;;;     (define (processa grafo-atual elems)
;;;         (if (null? elems)
;;;             grafo-atual
;;;             (let ((item (car elems))
;;;                 (resto (cdr elems)))
;;;             (cond
;;;                 ((symbol? item) 
;;;                 (processa (remove-vertice grafo-atual item) resto))
                
;;;                 ((pair? item)   
;;;                 (processa (remove-aresta grafo-atual item) resto))
                
;;;                 (else           
;;;                 (processa grafo-atual resto))))))
    
;;;     (processa g elementos)
;;; )


(display "Biblioteca TAGAS carregada...\n")



; running logic

; definição de estado inicial do grafo para a TAGAS
; (directed   (not) weighted   (not) direct-loop   body)
(define GRAFO '(#t #f #f ()))
(define HISTORICO (list GRAFO))

; print direto da TAGAS
(define (print)
    (display (getp GRAFO 'body))
)

(define DRAW-MODE #f)
(define DRAW-MSG "")

(define (set-draw-mode! bool msg)
    (begin
        (set! DRAW-MODE bool)
        (set! DRAW-MSG msg)
    )
)

(define (draw-update)
    (if DRAW-MODE
        (begin
            (display DRAW-MSG)
            (print)
        )
        (void)
    )
)

; Salva o estado atual do grafo no histórico, concretizando uma alteração do grafo
(define (GRAFO-to-historic!)
    (if (not (equal? GRAFO (car HISTORICO)))
        (begin
            (set! HISTORICO (cons GRAFO HISTORICO))
            (draw-update)
        )
        (void) ; Não adiciona ao histórico se não houve alteração no GRAFO
    )
)

; Desfaz a última alteração do grafo, restaurando o estado anterior do grafo no histórico
(define (undo!)
    (if (null? (cdr HISTORICO))
        (display "[WARNING] Não há histórico para desfazer.")
        (begin
            (set! HISTORICO (cdr HISTORICO))
            (set! GRAFO (car HISTORICO))
            (display "Última ALTERAÇÃO do grafo DESFEITA!")
            (draw-update)
        )
    )
)

; usado pela macro que relaciona diretamente o comando add da TAGAS
(define (add-vertex! V)
    (display "[DEBUG] Criando vértice ") (display V) ;(newline)
    (set! GRAFO (add-vertex GRAFO V))
)
; usado pela macro que relaciona diretamente o comando add da TAGAS
(define (add-edge! V1 V2)
    (display "[DEBUG] Criando aresta ") (display V1) (display ">") (display V2) ;(newline)
    (set! GRAFO (add-edge GRAFO V1 V2))
)

;;; ; possível utility - não está sendo usada pelas macros
;;; (define (add-vertexs! . vertexs)
;;;     (set! GRAFO (apply add-vertexs `(,GRAFO ,@vertexs)))
;;; )
;;; ; possível utility - não está sendo usada pelas macros
;;; (define (add-edges! . edges)
;;;     (set! GRAFO (apply add-edges `(,GRAFO ,@edges)))
;;; )

; usado pela macro que relaciona diretamente o comando remove da TAGAS
(define (remove-vertex! V)
    (display "[DEBUG] Removendo vértice ") (display V) ;(newline)
    (set! GRAFO (remove-vertice GRAFO V))
)
; usado pela macro que relaciona diretamente o comando remove da TAGAS
(define (remove-edge! V1 V2)
    (display "[DEBUG] Removendo aresta ") (display V1) (display ">") (display V2) ;(newline)
    (set! GRAFO (remove-aresta GRAFO (list V1 V2)))
)

(display "Lógica de runtime TAGAS carregada...\n")



; TAGAS syntax

; Dispatcher central
(define-syntax execute
  ;; TODOS os comandos oficiais da TAGAS aqui
  (syntax-rules (add remove print undo)
    
    ;; ---------------------------------------------------------
    ;; Comandos Mutáveis (Precisam salvar histórico)
    [ (execute add args ...)
      (begin
        (add args ...)
        (GRAFO-to-historic!)
      )
    ]
    [ (execute remove args ...)
      (begin
        (remove args ...) ; Supondo que você crie esse comando depois
        (GRAFO-to-historic!)
      )
    ]

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
    ;; Operadores '>' e '<>' como palavra-chave
    (syntax-rules (> <>)
        ;; 1. Casos base de parada da recursão
        [ (add) (void) ]

        ;; ERRO: checagem de sobra de operador
        [ (add >) (display "[ERRO] Mal uso de '>'.") ]
        [ (add <>) (display "[ERRO] Mal uso de '<>'.") ]
        [ (add xxx > > resto ...) (display "[ERRO] Mal uso de '>'.") ]
        [ (add xxx <> > resto ...) (display "[ERRO] Mal uso de '>'.") ]

        ;; 2. PADRÃO: Unidirecional (>)   ex: (add A > B)
        [ (add origem > destino resto ...)
            (begin
                (add-edge! 'origem 'destino)
                (add destino resto ...) ;; Continua processando o resto da linha
            )
        ]

        ;; 3. PADRÃO: Bidirecional (<>)   ex: (add A <> B)
        [ (add origem <> destino resto ...)
            (begin
                (add origem > destino)
                (add destino > origem)
                (add destino resto ...) ;; Continua processando o resto da linha
            )
        ]

        ;; 4. PADRÃO: Criar vértice apenas   ex: (add A)
        [ (add vertice resto ...)
            (begin
                (add-vertex! 'vertice)
                (add resto ...) ;; Continua processando o resto da linha
            )
        ]
    )
)

(define-syntax remove
    ;; Operadores '>' e '<>' como palavra-chave
    (syntax-rules (> <>)
        ;; 1. Casos base de parada da recursão
        [ (remove) (void) ]

        ;; ERRO: checagem de sobra de operador
        [ (remove > resto ...) (display "[WARNING] Operador '>' sobrando não causou efeito.\n") ]
        [ (remove <> resto ...) (display "[WARNING] Operador '<>' sobrando não causou efeito.\n") ]

        ;; 2. PADRÃO: Unidirecional (>)   ex: (remove A > B)
        [ (remove origem > destino resto ...)
            (begin
                (remove-edge! 'origem 'destino)
                (remove resto ...) ;; Continua processando o resto da linha
            )
        ]

        ;; 3. PADRÃO: Bidirecional (<>)   ex: (remove A <> B)
        [ (remove origem <> destino resto ...)
            (begin
                (remove origem > destino)
                (remove destino > origem)
                (remove resto ...) ;; Continua processando o resto da linha
            )
        ]

        ;; 4. PADRÃO: Remover vértice apenas   ex: (remove A)
        [ (remove vertice resto ...)
            (begin
                (remove-vertex! 'vertice)
                (remove resto ...) ;; Continua processando o resto da linha
            )
        ]
    )
)


(display "Macros de syntax TAGAS carregadas...\n")
(display "tagas.rkt CARREGADO até o final!  :D\n")