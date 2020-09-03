#lang eopl
(define empty-env
 (lambda ()
   `()
 )
)

(define extend-env* 
  (lambda (var val saved-env)
     (cons (cons var val) saved-env)
  )
)

(define search-helper
 (lambda (vars vals search-var)
  (if (null? vars)
     (cons 0 0)
     (if (equal? (car vars) search-var)
         (cons 1 (car vals))
         (search-helper (cdr vars) (cdr vals) search-var)
     )
  )
 )
)




(define apply-env 
 (lambda (search-var env)
   (if (null? env)
        (eopl:error "no such var:" search-var)
        (let* ([x (search-helper (caar env) (cdar env) search-var)]
               [ret (car x)]
               [answer (cdr x)]
              )
           (if (equal? ret 1)
               answer
              (apply-env search-var (cdr env))
           )
        )
   )
 )
)


(define test (extend-env* (list `a `b `c) (list 11 12 13) (extend-env* (list `x `z) (list 66 77) (extend-env* (list `x `y) (list 88 99) empty ))))
