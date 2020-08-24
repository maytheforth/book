#lang racket
(define (swapper s1 s2 slist)
(map (lambda (element)
      (cond
        [(list? element) (swapper s1 s2 element)]
        [(equal? element s1) s2]
        [(equal? element s2) s1]
        [else element]
      )
      )
  slist
)
)


(swapper "a" "d" `("a" "b" "c" "d"))
(swapper "a" "d" `("a" "d" () "c" "d"))
(swapper "x" "y" `(("x") "y" ("z" ("x"))))