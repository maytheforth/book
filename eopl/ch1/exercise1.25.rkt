#lang racket
(define (exists? pred lst)
(if (empty? lst)
    #f
    (or (pred (car lst)) (exists? pred (cdr lst)))
)
)

(exists? number? `("a" "b" "c" 3 "e"))
(exists? number? `("a" "b" "c" "d" "e"))