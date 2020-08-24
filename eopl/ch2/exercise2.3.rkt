#lang racket
(define zero
  (lambda ()
    (cons "diff" (cons `("one") `("one")))
  )
)

(define (compute n)
  (displayln n)
  (displayln (cadr n))
  (displayln (cddr n))
  (cond
     [(equal? n (car n)) 1]
     [else (- (compute (cadr n)) (compute (caddr n)))]
  )
)


; with multiple representation
(define is-zero?
 (lambda (n)
   (equal? (compute n) 0)
 )
)

; n ->  n - 1
(define predecessor
 (lambda (n)
   (cons "diff" (cons n `("one")))
 )
)

; n ->  n - (-1)
(define successor
(lambda (n)
 (define minusOne (predecessor (zero)))
 (cons "diff" (cons n minusOne))
)
)

(define myZero (zero))
(define myOne (successor myZero))
(compute myOne)
(define zeroAgain (predecessor myOne))
 zeroAgain


