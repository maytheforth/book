#lang eopl
(define-datatype lc-exp lc-exp?
 (var-exp (var symbol?))
 (lambda-exp
  (bound-var symbol?)
  (body   lc-exp?)
 )
 (app-exp
   (rator lc-exp?)
   (rand  lc-exp?)
 )
)

; struct -> string
(define unparse-lc-exp
(lambda (exp)
(cases lc-exp exp
 (var-exp (var) (symbol->string var))
 (lambda-exp (bound_var body)
    (string-append "(" "lambda (" (symbol->string bound_var) ")" (unparse-lc-exp body) ")")
 )
 (app-exp (rator rand) (string-append "(" (unparse-lc-exp rator) " " (unparse-lc-exp rand) ")"))
)
)
)

(define x (app-exp (lambda-exp `a (app-exp (var-exp `a) (var-exp `b))) (var-exp `c)))
(define y (unparse-lc-exp x))

(define z (lambda-exp `x (lambda-exp `y (app-exp (lambda-exp `x (app-exp (var-exp `x) (var-exp `y))) (var-exp `x)))))
(define q (unparse-lc-exp z))