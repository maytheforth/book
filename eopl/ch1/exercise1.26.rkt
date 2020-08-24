#lang racket
(define (up lst)
(cond
  [(empty? lst) empty]
  [else
   (cond
     [(not (list? (car lst))) (cons (car lst) (up (cdr lst)))] 
     [else (append (car lst) (up (cdr lst)))]
   )
  ]
)
)

(up `((1 2) (3 4)))
(up `((x (y)) z))