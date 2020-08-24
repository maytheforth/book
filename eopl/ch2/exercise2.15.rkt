#lang racket 
; lc-exp ::= identifier
;        ::= (lambda (identifier) lc-exp)
;        ::= (lc-exp lc-exp)
; var -> lc-exp
(define var-exp
(lambda (var)
  var
)
)

; lc-exp -> bool
(define var-exp?
  symbol?
)

; var * lc-exp -> lc-exp
(define lambda-exp
(lambda (var lc-exp)
  (list `lambda (list var) lc-exp)
)
)

; lc-exp -> bool
(define lambda-exp?
(lambda (lc-exp)
  (and (pair? lc-exp)
    (equal? (car lc-exp) `lambda)
   )
)
)

; lc-exp -> bool
(define lc-exp?
(lambda (lc-exp)
 (cond
   [(var-exp? lc-exp) #t]
   [(lambda-exp? lc-exp) #t]
   [(app-exp? lc-exp) #t]
   [else #f]
 )
)
)

; lc-exp * lc-exp -> lc-exp
(define app-exp
(lambda (lc-exp1 lc-exp2)
(list lc-exp1 lc-exp2)
)
)

; lc-exp -> bool
(define app-exp?
(lambda (lc-exp)
(cond
  [(list? lc-exp)
   (cond
     [(equal? (length lc-exp) 2) (and (lc-exp? (car lc-exp)) (lc-exp? (cadr lc-exp)))]
     [else #f]
   )
  ]
  [else #f]
)
)
)

(define var-exp->var
 (lambda (lc-exp)
   lc-exp
 )
)

(define lambda-exp->bound-var caadr)

(define lambda-exp->body caddr)

(define app-exp->rator car)

(define app-exp->rand cadr)


; my test 
(define test (lambda-exp `x `(+ 2 x)))
test
(lambda-exp? test)
(define var-test (var-exp `x))
(lambda-exp? var-test)
(define app-test (app-exp test var-test))
(define app-test2 (app-exp app-test test))
app-test
app-test2
(var-exp->var var-test)
(lambda-exp->bound-var test)
(lambda-exp->body test)
(app-exp->rator app-test)
(app-exp->rand app-test)


(app-exp? app-test)
(app-exp? app-test2)
(app-exp? var-test)
(app-exp? test)
