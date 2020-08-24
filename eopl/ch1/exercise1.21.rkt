#lang racket
(define (product sos1 sos2)
 ; elem * lst
(define (helper elem lst)
 (if (empty? lst)
     empty
     (cons (list elem (car lst)) (helper elem (cdr lst)))
 )
)
(if (empty? sos1)
    empty
    (append (helper (car sos1) sos2) (product (cdr sos1) sos2))
)
)

(product `("a" "b" "c") `("x" "y"))