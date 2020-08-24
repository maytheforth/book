#lang racket
(define (list-index pred lst)
(define (iter pred lst pos)
(cond
 [(empty? lst) #f]
 [(pred (car lst)) pos]
 [else (iter pred (cdr lst) (+ pos 1))]
)
)
(iter pred lst 0)
)

(list-index number? `("a" 2 (1 3) "b" 7))
(list-index string? `("a" ("b" "c") 17 "foo"))
(list-index string? `(1 2 ("a" "b") 3))