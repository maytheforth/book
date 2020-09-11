#lang eopl
(define the-store `uninitialized)
(define empty-store
  (lambda ()
    (vector)
 )
)

(define get-store
 (lambda ()
   the-store
 )
)

(define initialize-store!
 (lambda ()
   (set! the-store (empty-store))
 )
)

(define reference? integer?)

(define newref
 (lambda (saved-value)
   (let* ([lst (vector->list the-store)]
          [new-vector (list->vector (append lst (list saved-value)))]
         )
     (set! the-store new-vector)
     (- (vector-length new-vector) 1)
   )
 )
)

(define deref
 (lambda (n)
  (if (reference? n)
      (vector-ref the-store n)
      (eopl:error "error, invalid reference")
  )
 )
)

(define setref!
  (lambda (ref saved-value)
    (vector-set! the-store ref saved-value)
  )
)

(initialize-store!)
(define x (newref 0))
(deref x)
(setref! x 100)
(deref x)