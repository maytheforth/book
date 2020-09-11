#lang eopl
; empty-stack push pop top empty-stack?
(define empty-stack
 (lambda ()
    empty
 )
)

(define empty-stack? null?)

(define push
 (lambda (val stack)
   (append stack (list val))
 )
)

(define top
 (lambda (stack)
   (if (empty-stack? stack)
      (eopl:error "error,this is an empty stack")
      (list-ref stack (- (length stack) 1))
   )
 )
)


(define pop
 (lambda (stack)
    (if (empty-stack? stack)
        (eopl:error "error,this is an empty stack")
        (reverse (cdr (reverse stack)))
    )
 )
)




(define x (push 1 empty))
(define y (push 2 x))
(define z (push 3 y))
