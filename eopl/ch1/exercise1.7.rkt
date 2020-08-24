#lang racket
(define (nth-element vec pos)
(define (iter vec pos n)
(cond
  [(and (= pos n)(empty? vec)) (error "list should not be empty")]
  [(empty? vec) (format "list do not have ~a element" pos)]
  [(= n 0) (car vec)]
  [(> n 0) (iter (cdr vec) pos (- n 1))]
)
)
(iter vec pos pos)
)