#lang eopl
(define empty-env
 (lambda ()
   `()
 )
)

(define extend-env 
  (lambda (var val saved-env)
     (cons (cons var val) saved-env)
  )
)

(define apply-env 
 (lambda (search-var env)
   (if (null? env)
        (eopl:error "no such var:" search-var)
        (if (equal? (caar env) search-var)
            (cdar env)     
            (apply-env search-var (cdr env))
        )
   )
 )
)

(define extend-env*
  (lambda (vars vals saved-env)
    (if (null? vars)
        saved-env
       (extend-env* (cdr vars) (cdr vals) (extend-env (car vars)(car vals) saved-env))
    )
  )
)


(define x (list `a `b `c))
(define y (list 1 2 3))
(define z (extend-env* x y empty))