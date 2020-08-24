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

