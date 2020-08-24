#lang racket
; invert 1st
(define (invert lst)
(cond
  [(empty? lst) empty]
  [else (append (reverse (car lst)) (invert(cdr lst)))]
)
)