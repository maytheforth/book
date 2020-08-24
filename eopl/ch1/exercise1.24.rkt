#lang racket
(define (every? pred lst)
(cond
  [(empty? lst) #t]
  [(not (pred (car lst))) #f]
  [else (every? pred (cdr lst))]
)
)

(every? number? `("a" "b" "c" 3 e))
(every? number? `(1 2 3 4 5))