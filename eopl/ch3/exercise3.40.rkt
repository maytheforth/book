#lang eopl
(define run
 (lambda (string)
   (value-of-program (translation-of-program (scan&parse string)))
 )
)

(define value-of-program
 (lambda (pgm)
   (cases program pgm
     (a-program (exp1)
       (value-of exp1 (empty-nameless-env))
     )
   )
 )
)

(define translation-of-program
 (lambda (pgm)
  (cases program pgm
    (a-program (exp1) (a-program (translation-of exp1 (empty-senv))))
  )
 )
)

(define-datatype program program?
  (a-program (exp1 expression?))
)

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

; parser
(define grammar-a1
 '((program (expression) a-program)
   (expression (identifier) var-exp)
   (expression (number) const-exp)
   (expression ("-" "(" expression "," expression ")") diff-exp)
   (expression ("zero?" "(" expression ")") zero?-exp)
   (expression ("if" expression "then" expression "else" expression) if-exp)
   (expression ("let" identifier "=" expression "in" expression) let-exp)
   (expression ("proc" "(" identifier ")" expression) proc-exp)
   (expression ("(" expression expression ")") call-exp)
   (expression ("emptylist") emptylist-exp)
   (expression ("cons" "(" expression "," expression ")") cons-exp)
   (expression ("car" "(" expression ")") car-exp)
   (expression ("cdr" "(" expression ")") cdr-exp)
   (expression ("null?" "(" expression ")") null?-exp)
   (expression ("list" "("  (separated-list expression ",")")") list-exp)
   (expression ("unpack" (arbno identifier) "=" expression "in" expression) unpack-exp)
   (expression ("letrec" identifier "(" identifier ")" "=" expression "in" expression) letrec-exp)
 )
)

(define scan&parse (sllgen:make-string-parser scanner grammar-a1))

(define-datatype expression expression?
 (const-exp (num number?))
 (diff-exp (exp1 expression?) (exp2 expression?))
 (zero?-exp (exp1 expression?))
 (if-exp (exp1 expression?) (exp2 expression?) (exp3 expression?))
 (var-exp (var symbol?))
 (nameless-var-exp (num number?))
 (let-exp (var symbol?) (exp1 expression?) (body expression?))
 (nameless-let-exp (exp1 expression?)(body expression?))
 (proc-exp (var symbol?) (body expression?))
 (nameless-proc-exp (body expression?))
 (call-exp (rator expression?)(rand expression?))
 (emptylist-exp)
 (cons-exp (exp1 expression?) (exp2 expression?))
 (car-exp (body expression?))
 (cdr-exp (body expression?))
 (null?-exp (exp expression?))
 (list-exp (args (list-of expression?)))
 (unpack-exp (vars (list-of symbol?))(exp expression?)(body expression?))
 (nameless-unpack-exp (exp expression?) (body expression?))
 (letrec-exp (p-name symbol?) (p-var symbol?) (p-body expression?) (body expression?))
 (nameless-letrec-exp (p-proc expression?) (body expression?))
)

(define-datatype expval expval?
 (num-val (num number?))
 (bool-val (bool boolean?))
 (pair-val (left expval?)(right expval?))
 (emptylist-val)
 (proc-val (proc proc?))
)

(define-datatype proc proc?
  (procedure (body expression?)(saved-env vector?))
)

; ---------------------------------------------------------------
(define-datatype environment environment?
  (empty-env)
  (extend-env (var symbol?) (val expval?) (saved-env environment?))
)

(define apply-env
 (lambda (env search-var) 
  (cases environment env
    (empty-env () (eopl:error "can not find such var" search-var))
    (extend-env (var val saved-env)
       (if (equal? var search-var)
          val
         (apply-env saved-env search-var)
       )
    )
  )
 )
)


  
(define list-val
 (lambda (args)
   (if (null? args)
       (emptylist-val)
       (pair-val (car args) (list-val (cdr args)))
   )
 )
)
  

(define init-env
  (lambda ()
    (extend-env `a (num-val 1) (extend-env `b (num-val 2) (extend-env `c (num-val 3) (empty-env))))
  )
)

;---------------------------------------senv-------------------------------------------
(define empty-senv
 (lambda ()
   `()
 )
)

(define extend-senv
  (lambda (var saved-env)
    (cons var saved-env)
  )
)

(define extend-senv-with-list
 (lambda (vars saved-env)
   (if (null? vars)
      saved-env
      (extend-senv-with-list (cdr vars) (extend-senv (car vars) saved-env))
   )
 )
)

(define apply-senv
 (lambda (env search-var)
   (if (null? env)
     (eopl:error "no such var:" search-var)
     (if (equal? search-var (car env))
         0
        (+ 1 (apply-senv (cdr env) search-var))
     )
   )
 )
)

;-------------------------------------nameless-env -------------------------------------
(define nameless-env?
 (lambda (x)
   ((list-of expval?) x)
 )
)

(define empty-nameless-env
 (lambda()
  `()
 )
)

(define extend-nameless-env
 (lambda (val saved-env)
   (cons val saved-env)
 )
)

(define extend-nameless-env-with-list
 (lambda (vals saved-env)
   (if (null? vals)
       saved-env
      (extend-nameless-env-with-list (cdr vals) (extend-nameless-env (car vals) saved-env))
   )
 )
)



(define apply-nameless-env
 (lambda (env n)
  (if (null? env)
     (eopl:error "environment is empty")
     (list-ref env n)
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


(define expval->proc
 (lambda (val)
  (cases expval val
    (proc-val (proc) proc)
    (else (eopl:error "error type to proc"))
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

(define expval->list
 (lambda (exp)
   (cases expval exp
     (pair-val (exp1 exp2) (append (expval->list exp1) (expval->list exp2)))
     (emptylist-val () empty)
     (else (list exp))
   )
 )
)

(define value-of
 (lambda (exp env)
   (cases expression exp
     (const-exp (num) (num-val num))
     (nameless-var-exp (num) (apply-nameless-env env num))
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
     (emptylist-exp ()
       (emptylist-val)
     )
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
    (nameless-let-exp (exp1 body)
       (let ([val1 (value-of exp1 env)])
         (value-of body (extend-nameless-env val1 env))
       )
    )
     (nameless-proc-exp (body)
       (proc-val (procedure body (vector env)))
     )
     (call-exp (left right)
       (let ([x (expval->proc (value-of left env))]
             [arg (value-of right env)]
            )
         (cases proc x
           (procedure (body saved-env) (value-of body (extend-nameless-env arg (vector-ref saved-env 0))))
         )
       )
     )
    (nameless-unpack-exp (exp body)
      (let* ([listval (value-of exp env)]
             [vals (expval->list listval)]
            )
        (value-of body (extend-nameless-env-with-list vals env))
      )
    )
    (nameless-letrec-exp (p-proc body)
      (display p-proc)
      (display "++++++\n")
      (let ([new-env (extend-nameless-env-with-list p-proc env)])        
        (value-of body new-env)
      )
    )
    (else (eopl:error "error type to value-of"))    
  )
 ) 
)


(define translation-of 
 (lambda (exp env)
   (cases expression exp
     (const-exp (num) (const-exp num))
     (var-exp (var) (nameless-var-exp (apply-senv env var)))
     (diff-exp (exp1 exp2) (diff-exp (translation-of exp1 env) (translation-of exp2 env)))
     (zero?-exp (exp) (zero?-exp (translation-of exp env)))
     (if-exp (exp1 exp2 exp3)
     (if-exp
       (translation-of exp1 env)
       (translation-of exp2 env)
       (translation-of exp3 env)
     )
     ) 
     (let-exp (var exp1 body)
      (nameless-let-exp
        (translation-of exp1 env)
        (translation-of body (extend-senv var env))
      )
     )
     (emptylist-exp () (emptylist-exp))
     (cons-exp (exp1 exp2)
       (cons-exp 
        (translation-of exp1 env)
        (translation-of exp2 env)
       )
     )
     (car-exp (body)
      (car-exp (translation-of body env))
     )
     (cdr-exp (body)
      (cdr-exp (translation-of body env))
     )
     (null?-exp (exp)
       (null?-exp (translation-of exp env))
     )
     (list-exp (args)
       (list-exp (map (lambda (arg) (translation-of arg env)) args))
     )
     (proc-exp (var body)
      (nameless-proc-exp (translation-of body (extend-senv var env)))
     )
     (call-exp (left right)
      (call-exp (translation-of left env) (translation-of right env))
     )
     (unpack-exp (vars exp body)
       (nameless-unpack-exp 
         (translation-of exp env)
         (translation-of body (extend-senv-with-list vars env))
       )
     )
     (letrec-exp (p-name p-var p-body body)
      (let ([new-env (extend-senv p-name env)])
       (nameless-letrec-exp
          (translation-of (proc-exp p-var p-body) new-env)
          (translation-of body new-env)
       )
      )
     )
     (else (eopl:error "error type to translation-of "))
   )
 )
)


(define extend-env-rec
 (lambda (p-name b-var p-body env)
   (let* ([vec (make-vector 1)]
          [newproc (proc-val (procedure b-var p-body vec))]
          [new-env (extend-env p-name newproc env)]
         )
    (vector-set! vec 0 new-env)
    new-env
   )
 )
)


(define cons-x (run "(proc(x) -(x,1) 7)
  "
))

(define letrec-x (translation-of-program (scan&parse "letrec double(x) =
                      if zero?(x) then 0 else -((double -(x,1)),-2)
                      in (double 6)
   "
 )
)
)