#lang racket
(define (flatten slist)
(cond
  [(empty? slist) empty]
  [(list? slist)(append (flatten (car slist)) (flatten (cdr slist)))]
  [else (cons slist empty)]
)
)

(flatten `(a b c))
(flatten `((a) () (b ()) () (c)))
(flatten `((a b) c (((d)) e)))
(flatten `(a b (() (c))))
