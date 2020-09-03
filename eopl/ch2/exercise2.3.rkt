#lang eopl
;zero is-zero? successor predecessor
; diff-tree::= (one) | (diff diff-tree diff-tree)
(define zero
 (lambda ()
   (list `diff (list `one) (list `one))
 )
)

(define is-zero?
 (lambda (n)
   (equal? (compute n) 0)
 )
)

(define predecessor
 (lambda (n)
   (list `diff  n (list `one))
 )
)

(define successor
 (lambda (n)
   (list `diff n (predecessor (zero)))
 )
)

(define compute
 (lambda (n)
   (if (equal? n (list `one))
       1
       (- (compute (cadr n)) (compute (caddr n)))
   )
 )
)

; h1 = (- a b) = (a - b)
; h2 = (- c d) = (c - d)
; h1 + h2 = (a - b) + (c - d) = (a - d) - (b - c)

(define diff-tree-plus
 (lambda (n1 n2)
   (cond
      [(equal? n1 (list `one)) (successor n2)]
      [(equal? n2 (list `one)) (successor n1)]
      [else (list `diff (list `diff (cadr n1) (caddr n2)) (list `diff (caddr n1) (cadr n2))) ]
   )
 )
)

(define diff-tree-plus1
  (lambda (m n)
    (list `diff m (list `diff (zero) n))
  )
)



(define myZero (zero))
(define myOne (successor myZero))
(define myTwo (successor myOne))
(define myFour (diff-tree-plus myTwo myTwo))
(define myFive (successor myFour))
(compute myOne)
(define zeroAgain (predecessor myOne))
 zeroAgain




