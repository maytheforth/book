#lang racket
;(duple n x) n copies of x
(define (duple n x)
(cond
  [(zero? n) empty]
  [else (cons x (duple (- n 1)x))]
)
)

(duple 2 3)
(duple 4 `("ha" "ha"))
(duple 0 `("blah"))