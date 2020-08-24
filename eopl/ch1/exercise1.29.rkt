#lang racket
(define (sort loi)
; add a element to a sorted list
(define (add elem slist)
(cond
  [(empty? slist) (list elem)]
  [(< elem (car slist)) (append (list elem) slist)]
  [(>= elem (car slist))(append (list (car slist))(add elem (cdr slist)))]
)
)
(cond
  [(= (length loi) 1) loi]
  [(= (length loi) 2)
   (if (< (car loi) (car (cdr loi)))
       loi
       (append (cdr loi) (cons (car loi) empty))
   )
  ]
  [else (add (car loi) (sort (cdr loi)))]
)
)

(sort `(8 2 5 2 3))
(sort `(4 83 37 98 69 11 91 54 17 16))