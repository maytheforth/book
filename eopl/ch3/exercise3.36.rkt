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
    (number ("-" digit (arbno digit)) number)
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
   (expression ("(" expression (arbno expression) ")") call-exp)
   ; 3.21 change from single argument to multiple arguments 
   (expression ("proc" "("  (separated-list identifier ",") ")" expression) proc-exp)
   ; 3.27 traceproc
   (expression ("traceproc" "(" (separated-list identifier ",") ")" expression) traceproc-exp)
   ; 3.31 letrec
   (expression ("letrec" (arbno identifier "(" (separated-list identifier ",") ")" "=" expression ) "in" expression) letrec-exp)
  )
)

(define scan&parse (sllgen:make-string-parser scanner grammar-a1))

;------------------------------------------define env
(define-datatype environment environment?
 (empty-env)
 (extend-env
   (var symbol?)
   (val (lambda (val)
        (or (expval? val) (vector? val))
    )
   )
   (env environment?)
  )
)

(define extend-helper
 (lambda (p-names saved-env record)
   (if (null? p-names)
       record
       (if (null? record)
         (let* ([vec (make-vector 1)]
                [new-env (extend-env (car p-names) vec saved-env)]
                [new-record (cons new-env (list vec))])
               (extend-helper (cdr p-names) saved-env new-record)
         )
         (let* ([old-env (car record)]
                [vec (make-vector 1)]
                [new-env (extend-env (car p-names) vec old-env)]
                [new-record (cons new-env (append (cdr record) (list vec)))]
         )
       (extend-helper (cdr p-names) saved-env new-record)
    )
   )
   )
 )
)



(define extend-env-rec
 (lambda (p-names b-vars bodys saved-env)
   (let* ([record (extend-helper p-names saved-env empty)]
          [new-env (car record)]
          [vec-list (cdr record)]
         )
      (map (lambda (b-var body vec)
             (vector-set! vec 0 (proc-val (procedure b-var body new-env #f)))
             1
           )
        b-vars bodys vec-list)
      new-env
   )
 )
)



(define apply-env
 (lambda (env search-var)
   (cases environment env
     (empty-env () (display "error, found no such var"))
     (extend-env (saved-var saved-val saved-env)
       (if (equal? saved-var search-var)
             (if (vector? saved-val)
                 (vector-ref saved-val 0)
                 saved-val
             )
            (apply-env saved-env search-var)
        )
      )
   )
 )
)


(define init-env
 (lambda()
   (empty-env)
 )
)


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
 ; add proc-exp call-exp
 (proc-exp (args (list-of symbol?)) (body expression?))
 (call-exp (rator expression?) (rand (list-of expression?)))
 ; add traceproc-exp
 (traceproc-exp (args (list-of symbol?)) (body expression?))
 ; add letrec
 (letrec-exp (p-names (list-of symbol?)) (bound-vars (list-of (list-of symbol?))) (p-bodys (list-of expression?)) (letrec-body expression?))
)


(define-datatype expval expval?
 (num-val (num number?))
 (bool-val (bool boolean?))
 (pair-val (car expval?)(cdr expval?))
 (emptylist-val)
 (proc-val (proc proc?))
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

(define expval->proc
 (lambda (exp)
   (cases expval exp
     (proc-val (proc) proc)
     (else (display "error, not a proc"))
   )
 )
)


(define expval->proc?
 (lambda (exp)
   (cases expval exp
     (proc-val (proc) #t)
     (else #f)
   )
 )
)



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
    (proc-exp (vars body)
      (proc-val (procedure vars body env #f))
    )
    (traceproc-exp (vars body)
      (proc-val (procedure vars body env #t))
    )
    (call-exp (rator rand)
       (let* ([proc (expval->proc (value-of rator env))]
              [args (map (lambda(x) (value-of x env))
				     rand)])
         (apply-procedure proc args)
       )
    )
    ; add letrec-exp
    (letrec-exp (p-names b-vars p-bodys letrec-body)
       (value-of letrec-body (extend-env-rec p-names b-vars p-bodys env))
    )
  )
 ) 
)
; ----------------------------------add procedure

(define-datatype proc proc?
 (procedure 
   (args (list-of symbol?))
   (body expression?)
   (saved-env environment?)
   (flag boolean?)
 )
)

(define apply-procedure
 (lambda (proc1 vals)
   (cases proc proc1
     ( procedure (vars body saved-env flag)
         (if flag (display "traceproc enter\n") `())
         (let ([x (value-of body (extend-env-with-list vars vals saved-env))])
           (if flag (display "traceproc exit\n") `())
           x
         )
     )
   )
 )
)

(define extend-env-with-list
 (lambda (vars vals saved-env)
   (if (null? vals)
        saved-env
        (extend-env-with-list (cdr vars) (cdr vals) (extend-env (car vars) (car vals) saved-env))
   )
 )
)

;----------------------------------------------- run test


(define letrec-x (run "letrec
                          even(x) = if zero?(x) then 1 else (odd -(x,1))
                          odd(x) = if zero?(x) then 0 else (even -(x,1))
                          in (odd 13)
  ")
)






