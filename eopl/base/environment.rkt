#lang eopl
(define empty-env
 (lambda ()
   `()
 )
)

(define extend-env
  (lambda (var val saved-env)
    (cons (list var val) saved-env)
  )
)

(define apply-env
 (lambda (env search-var)
   (if (null? env)
       (display "error, no such var")
       (let* ([var (caar env)]
              [val (cadar env)]
              [nest-env (cdr env)])
         (if (equal? var search-var)
            val
            (apply-env nest-env search-var)
         )
       )
   )
 )
)

(define environment?
 (lambda (env)
  (or
   (null? env)
   (and (pair? env)
        (symbol? (caar env))
        (expval? (cadar env))
        (environment? (cdr env))
   )
  )
 )
)


(define init-env
 (lambda()
   (extend-env
     `i (num-val 1)
       (extend-env
           `v (num-val 5)
             (extend-env
                `x (num-val 10)
                  (empty-env)
             )
       )
    )
 )
)