#lang racket
;(duple n x) n copies of x
(define (down lst)
(
if (empty? lst)
empty
(cons (list (car lst)) (down (cdr lst)))
)
)
