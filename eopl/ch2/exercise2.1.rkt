#lang racket
; 16进制表示数字
(define zero
(lambda ()
  `()
)
)

(define is-zero?
( lambda(n)
  (empty? n)
)
)

(define successor
(lambda (n)
 (cond
   [(is-zero? n) `(1)]
   [(>=  (+ (car n) 1)  16) (append (list (- 16 (+ (car n) 1))) (successor (cdr n)))]
   [else (append (list (+ (car n) 1)) (cdr n))]
 )
)
)

(define precedessor
(lambda (n)
 (cond
  [(is-zero? n) (error "error")]
  [(equal? n `(1)) `()]
  [(equal? 0 (car n)) (append `(15) (precedessor (cdr n)))]
  [else (append (list (- (car n) 1)) (cdr n))]
  )
)
)

(define (plus x y)
 (if (is-zero? x)
     y
    (successor (plus (precedessor x) y))
 )
)

(define (multiple x y)
(cond
  [(is-zero? x) `()]
  [(equal? x `(1)) y]
  [else (plus y (multiple (precedessor x) y))]
)
)

(define (factorial n)
(if (equal? n `(1))
    `(1)
    (multiple (factorial (precedessor n)) n)
)
)

(factorial `(10))






