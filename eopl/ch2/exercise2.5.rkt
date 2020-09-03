#lang racket
; () -> env
(define empty-env
(lambda ()
  empty
)
)

; variable * value * env -> env
(define extend-env
(lambda (var val env)
 (cons (cons var val) env)
)
)

(define apply-env
(lambda (env search-var)
(cond
  [(empty? env) (displayln "can not find variable")]
  [(equal? (caar env) search-var) (cdar env)]
  [else (apply-env (cdr env) search-var)]
)
)
)

(define test
  (extend-env "name" "lee" empty)
)
(apply-env test "name")
(apply-env test "age")

; a = 1 , b = 2 , c = 3
; seperate list for key and vals
; (a b c) (1 2 3)

; key-value pair in list
; ((a 1) (b 2) (c 3))

; like hashmap
; a = 1  b = 2 a = 3
; ((a 1 3) (b 2))


