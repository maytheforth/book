#lang eopl

; ------------------------------------ string->exp ----------------------------------------
; scanner
; scanner ::= (regexp-and-action ..)
; regexp-and-action ::= (name (regexp ...) outcome)
; outcome ::= skip | symbol | string | number 
; regexp ::= tester | (or regexp ..) | (arbno regexp) | (concat regexp ...)
; tester :: = string | letter | digit | whitespace | any | (not char) {other than given char}
;
(define scanner
  '((white-sp (whitespace) skip)
    (comment (";" (arbno (not #\newline))) skip)
    (identifier (letter (arbno (or letter digit "_" "-" "?"))) symbol)
    (number (digit (arbno digit)) number)
   )
)


; grammar := (production ...)
; production ::= (lhs rhs prod-name)
; lhs ::= symbol
; rhs ::= (rhs-item ...)
; rhs-item ::= symbol | string | (ARBNO rhs-item ...) | (SEPARATED-LIST rhs-item ... token)
; prod-name ::= symbol

; parser
(define grammar-a1
 '((program (expression) a-program)
   (expression (identifier) var-exp)
   (expression (number) const-exp)
   (expression ("-" "(" expression "," expression ")") diff-exp)
   (expression ("zero?" "(" expression ")") zero?-exp)
   (expression ("if" expression "then" expression "else" expression) if-exp)
   (expression ("let" identifier "=" expression "in" expression) let-exp)
   ; new add "add" "minus" "multiply" "div"
   (expression ("+" "(" expression "," expression ")") add-exp)
   (expression ("*" "(" expression "," expression ")") mult-exp)
   (expression ("/" "(" expression "," expression ")") div-exp)
   (expression ("minus" "(" expression ")") minus-exp)
   ; add "equal?" "greater?" "less?"
   (expression ("equal?" "(" expression "," expression ")") equal?-exp)
   (expression ("greater?" "(" expression "," expression ")") greater?-exp)
   (expression ("less?" "(" expression "," expression ")") less?-exp)
   (expression ("emptylist") emptylist-exp)
   ; add "cons"
   (expression ("cons" "(" expression "," expression ")") cons-exp)
   (expression ("car" "(" expression ")") car-exp)
   (expression ("cdr" "(" expression ")") cdr-exp)
   (expression ("null?" "(" expression ")") null?-exp)
   ; add "list"
   (expression ("list" "("  (separated-list expression ",")")") list-exp)
   ; 3.12 add "cond"
   (expression ("cond" (arbno "{" expression "==>" expression "}") "end") cond-exp)
   (expression ("unpack" (arbno identifier) "=" expression "in" expression) unpack-exp)
 )
)

(define scan&parse (sllgen:make-string-parser scanner grammar-a1))


; -------------------------------------- add new grammar -------------------------------------

(define-datatype program program?
  (a-program (exp1 expression?))
)



(define-datatype expression expression?
 (const-exp (num number?))
 (diff-exp (exp1 expression?) (exp2 expression?))
 (zero?-exp (exp1 expression?))
 ; exercise 3.6 add minus
 (minus-exp (exp1 expression?))
 ; exercise 3.7 add addition
 (add-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.7 add multiplication
 (mult-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.7 add integer quotient
 (div-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.8 add equal?
 (equal?-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.8 add greater?
 (greater?-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.8 add less?
 (less?-exp (exp1 expression?) (exp2 expression?))
 ; exercise 3.9 add emptylist
 (emptylist-exp)
  ; exercise 3.9 add cons
 (cons-exp (exp1 expression?) (exp2 expression?))
  ; exercise 3.9 add car
 (car-exp (body expression?))
  ; exercise 3.9 add cdr
  (cdr-exp (body expression?))
  ; exercise 3.9 add null?
  (null?-exp (exp expression?))
  ;exercise 3.10 add list
  (list-exp (args (list-of expression?)))
  ;exercise 3.12 add cond
  (cond-exp (conditions (list-of expression?)) (actions (list-of expression?)))
 (if-exp (exp1 expression?) (exp2 expression?) (exp3 expression?))
 (var-exp (var symbol?))
 (let-exp (var symbol?) (exp1 expression?) (body expression?))
 (unpack-exp (vars (list-of symbol?)) (exp expression?) (body expression?))
)


(define-datatype expval expval?
 (num-val (num number?))
 (bool-val (bool boolean?))
 (pair-val (car expval?)(cdr expval?))
 (emptylist-val)
; (proc-val (proc proc?))
)

(define list-val
 (lambda (args)
   (if (null? args)
       (emptylist-val)
       (pair-val (car args) (list-val (cdr args)))
   )
 )
)



(define cond-val
 (lambda (conditions actions env)
   (cond
     [(null? conditions) (display "error , no tests succeed")]
     [else
      (let* ([val (value-of (car conditions) env)]
             [value (expval->bool val)])
        (if value
            (value-of (car actions) env)
            (cond-val (cdr conditions) (cdr actions) env)
        )
      )
     ]
   )
 )
)



; expval -> int
(define expval->num
 (lambda (val)
   (cases expval val
     (num-val (num) num)
     (else (display "error type to int"))
   )
 )
)

; expval-> list
(define expval->list
 (lambda(val)
   (cases expval val
     (emptylist-val () empty)
     (pair-val (left right) (append (append empty (expval->list left)) (append empty (expval->list right))))
     (else (list val))
   )
 )
)

; expval -> bool
(define expval->bool
 (lambda(val)
   (cases expval val
     (bool-val (bool) bool)
     (else (display "error type to bool"))
   )
 )
)

; pair-val -> car pair-val
(define expval->car
  (lambda (exp)
    (cases expval exp
      (pair-val (exp1 exp2) exp1)
      (else (display "format error, not pair-val"))
    )
  )
)

; pair-val -> cdr pair-val
(define expval->cdr
  (lambda (exp)
    (cases expval exp
      (pair-val (exp1 exp2) exp2)
      (else (display "format error, not pair-val"))
    )
  )
)


; exp-val? -> null?
(define expval->null?
 (lambda (exp)
   (cases expval exp
     (emptylist-val () (bool-val #t))
     (else (bool-val #f))
   )
 )
)


; empty-env
(define empty-env
 (lambda ()
   (lambda (search)
     (display "error, it's an empty env")
   )
 )
)

; extend-env
(define extend-env
(lambda (saved-var saved-val saved-env)
 (lambda (search-var)
   (if (equal? search-var saved-var)
       saved-val
       (apply-env saved-env search-var)
   )
 )
)
)


(define extend-env-with-list
 (lambda (varlist vallist env)
  (cond
    [(not (equal? (length varlist) (length vallist))) (display "error, no match")]
    [(null? varlist) env]
    [else (extend-env-with-list (cdr varlist) (cdr vallist) (extend-env (car varlist) (car vallist) env))]
  )
 )
)





; apply-env
(define apply-env
 (lambda (env search-var)
   (env search-var)
 )
)

; (define-datatype proc proc?
;    (procedure (var symbol?) (body expression?) (saved-env environment?))
; )

;(define apply-procedure
; (lambda (proc1 val)
;   (cases proc proc1
;     (procedure (var body saved-env) (value-of body (extend-env var val saved-env)))
;   )
;  )
;)


;string -> expval
(define run
  (lambda (string)
    (value-of-program (scan&parse string))
 )
)

; program -> expval
(define value-of-program
 (lambda (pgm)
   (cases program pgm
     (a-program (exp1) (value-of exp1 (init-env)))
   )
 )
)


; exp * env -> expval
(define value-of
 (lambda (exp env)
   (cases expression exp
     (const-exp (num) (num-val num))
     (var-exp (var) (apply-env env var))
     (diff-exp (exp1 exp2)
       (let* ([val1 (value-of exp1 env)]
              [val2 (value-of exp2 env)]
              [num1 (expval->num val1)]
              [num2 (expval->num val2)]
             )
         (num-val (- num1 num2))
       )
     )
     (zero?-exp (exp1)
       (let* ([val1 (value-of exp1 env)]
              [num1 (expval->num val1)]
              )
         (if (zero? num1) (bool-val #t) (bool-val #f))
       )
      )
     (if-exp (exp1 exp2 exp3)
       (let ([val1 (value-of exp1 env)])
         (if (expval->bool val1)
             (value-of exp2 env)
             (value-of exp3 env)
         )
       )
      )
      (let-exp (var exp1 body)
        (let ([val1 (value-of exp1 env)])
          (value-of body (extend-env var val1 env))
        )
      )
      ; exercise 3.6 add minus
     (minus-exp (exp1)
      (let ([val (value-of exp1 env)])
        (num-val (* (expval->num val) -1))
      )
     )
     ; exercise 3.7 add addition
     (add-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (num-val (+ num1 num2))
      )
     )
     ; exercise 3.7 add multiplication
     (mult-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (num-val (* num1 num2))
      )
     )
     ; exercise 3.7 add division
     (div-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (num-val (quotient num1 num2))
      )
     )
     ; exercise 3.8 add equal?
     (equal?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (bool-val (equal? num1 num2))
      )
     )
     ; exercise 3.8 add greater?
      (greater?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (bool-val (> num1 num2))
      )
     )
     ; exercise 3.8 add less?
      (less?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (bool-val (< num1 num2))
      )
     )
     ; exercise 3.9 add emptylist
     (emptylist-exp ()
       (emptylist-val)
     )
     ; exercise 3.9 add cons
     (cons-exp (exp1 exp2) 
      (let* (
         [val1 (value-of exp1 env)]
         [val2 (value-of exp2 env)])
        (pair-val val1 val2)
      )
     )
    (car-exp (exp)
     (let ([val (value-of exp env)])
       (expval->car val)
     )
    )
    (cdr-exp (exp)
     (let ([val (value-of exp env)])
       (expval->cdr val)
     )
    )
    (null?-exp (exp)
      (let ([val (value-of exp env)])
        (expval->null? val)
      )
    )
    (list-exp (args)
      (list-val (map (lambda (exp) (value-of exp env)) args))
    )
    (cond-exp (conditions actions)
        (cond-val conditions actions env)
    )
    (unpack-exp (vars exp body)
      (let ([expvallist (expval->list (value-of exp env))])
         (value-of body (extend-env-with-list vars expvallist env))
      )        
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


(define test (run "let x = 7
                   in let y = 2
                      in let y = let x = -(x,1)
                                     in -(x,y)
                      in -(-(x,8),y)
 "))
; exercise 3.6  add a new operator `minus` that take one argument n , and return -n
(define test-3.6 (run "minus(-(minus(5),9))"))

; exercise 3.7 add operators for addition, multiplication , and integer quotient
(define add-x (run "+ (3 , 4)"))

(define mult-x (run "let x = 4 in *(x,3)"))

(define div-x (run "/(3 , 2)"))

; exercise 3.8 add equal? , greater?,less?
(define equal-x (run "equal?(3,2)"))

(define greater-x (run "greater?(3,2)"))

(define less-x (run "less?(3,2)"))

(define empty-x (run "emptylist"))

(define cons-x (run "let x = 4
                     in cons(x,
                          cons(cons(-(x,1),emptylist),
                     emptylist))"
))


(define car-x (run "let x = 4
                     in car(cons(x,
                           cons(cons(-(x,1),emptylist),
                     emptylist)))"
))

(define cdr-x (run "let x = 4
                     in cdr(cons(x,
                           cons(cons(-(x,1),emptylist),
                     emptylist)))"
))

(define null?-x (run "null?(emptylist)" ))

(define list-x (run "let x = 4
                     in list (x, -(x,1), -(x,3))"
))


; add "cond" test
(define cond-x (run "let x  = 9
                       in cond { greater?(x,10)==>  -(x,10)}
                               { less?  (x,10) ==>  +(x,10)}end "
))


(define unpack-x (run "let u = 7
                       in unpack x y = cons(u,cons(3,emptylist))
                       in -(x,y)
"
 )
)

