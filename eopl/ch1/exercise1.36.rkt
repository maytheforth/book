#lang racket
(define g
(lambda (head tail)
(cons head
   (map (lambda (item)
          (list (+ (car item) 1) (cadr item))
         )
    tail
   )
)
)
)
(define number-elements

(lambda (slst)
(if (empty? slst)
    empty
    (g (list 0 (car slst)) (number-elements (cdr slst)))
)
)
)

(number-elements (list "a" "b" "c" "d" "e" "f"))