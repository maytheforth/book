#lang racket
(define number->sequence
 (lambda (number)
   (list number empty empty)
 )
)

(define current-element
(lambda (seq)
  (car seq)
)
)

(define at-left-end?
(lambda (seq)
 (empty? (cadr seq))
)
)

(define at-right-end?
(lambda (seq)
 (empty? (caddr seq))
)
)

(define insert-to-left
(lambda (num seq)
  (list (car seq) (cons num (cadr seq)) (caddr seq))
)
)

(define insert-to-right
(lambda (num seq)
  (list (car seq) (cadr seq) (cons num (caddr seq)))
)
)



(define move-to-left
(lambda (seq)
  (if (at-left-end? seq) (error "can not move-to-left") (list (caadr seq) (cdadr seq) (cons (car seq) (caddr seq)) ))
)
)

(define move-to-right
(lambda (seq)
  (if (at-right-end? seq) (error "can not move-to-right") (list (caaddr seq) (cons (car seq) (cadr seq)) (cdaddr seq) ))
)
)

; test 
(define x `(6 (5 4 3 2 1) (7 8 9)))
x
(current-element x)
(move-to-left x)
(define y (move-to-right ( move-to-right (move-to-right x))))
y
(at-right-end? y)
;(move-to-right y)
(define z `(1 () (2 3 4 5)))
z
(at-left-end? z)
;(move-to-left z)
(insert-to-left 13 x)
(insert-to-right 13 x)