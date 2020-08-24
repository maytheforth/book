#lang racket
(define (sort/predicate pred loi)
; add a element to a sorted list
(define (add pred elem slist)
(cond
  [(empty? slist) (list elem)]
  [(pred elem (car slist)) (append (list elem) slist)]
  [else (append (list (car slist))(add pred elem (cdr slist)))]
)
)
(cond
  [(= (length loi) 1) loi]
  [(= (length loi) 2)
   (if (pred (car loi) (car (cdr loi)))
       loi
       (append (cdr loi) (cons (car loi) empty))
   )
  ]
  [else (add pred (car loi) (sort/predicate pred (cdr loi)))]
)
)

(sort/predicate < `(8 2 5 2 3))
(sort/predicate > `(8 2 5 2 3))