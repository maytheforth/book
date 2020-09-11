#lang eopl
(define empty-env
  (lambda ()
    (cons
      (lambda (search-var)
        (eopl:error "no such var" search-var)
      )
      (cons 
        (lambda (search-var)
           #f
        )
        #t
      )
    )
  )
)

(define extend-env
 (lambda (saved-var saved-val saved-env)
  (cons
    (lambda (search-var)
      (if (equal? search-var saved-var)
          saved-val
         (apply-env saved-env search-var)
      )
    )
    (cons
      (lambda (search-var)
       (if (equal? search-var saved-var)
           #t
          (has-binding? saved-env search-var)
       )
      )
       #f
    )
  )
 )
)


(define apply-env
 (lambda (env search-var)
   ((car env) search-var)
 )
)

(define empty-env?
  (lambda (env)
    (cddr env)
  )
)

(define has-binding?
 (lambda (env s)
   ((cadr env) s)
 )
)


(define test (extend-env `a 1 (extend-env `b 2 (extend-env `c 3 (empty-env)))))





