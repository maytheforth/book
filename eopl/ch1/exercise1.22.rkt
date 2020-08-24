#lang racket
(define (filter-in pred lst)
(define (iter pred lst answer)
 (cond
   [(empty? lst) answer]
   [(not (list? (car lst)))
   (if (pred (car lst))
      (iter pred (cdr lst) (append answer (cons (car lst) empty)))
      (iter pred (cdr lst) answer)
   )
   ]
   [else (iter pred (cdr lst) answer)]
 )
  
)
(iter pred lst empty)
)  

(filter-in number? `("a" 2 (1 3) "b" 7))
(filter-in string?`("a" ("b" "c") 17 "foo"))