#lang eopl
(define empty-stack
 (lambda()
  (lambda (command)
   (cond
     [(equal? command `empty?) #t]
     [(equal? command `pop) (eopl:error "this is an empty stack, can not pop")]
     [(equal? command `top) (eopl:error "this is an empty stack ,can not top")]
   )
  )
 )
)

(define push
 (lambda (val stack)
   (lambda (command)
    (cond
      [(equal? command `pop) stack]
      [(equal? command `top) val]
      [(equal? command `empty?) #f]
    )
   )
 )
)

(define pop
 (lambda (stack)
   (stack `pop)
 )
)

(define top
 (lambda (stack)
   (stack `top)
 )
)

(define empty?
 (lambda (stack)
   (stack `empty?)
 )
)

(define y (push 1 (push 2 (empty-stack))))