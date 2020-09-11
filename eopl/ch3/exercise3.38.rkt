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
   (expression ("equal?" "(" expression "," expression ")") equal?-exp)
   (expression ("greater?" "(" expression "," expression ")") greater?-exp)
   (expression ("less?" "(" expression "," expression ")") less?-exp)
   (expression ("cond" (arbno "{" expression "==>" expression "}") "end") cond-exp)
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
 (equal?-exp (left expression?) (right expression?))
 (greater?-exp (left expression?) (right expression?))
 (less?-exp (left expression?) (right expression?))
 (cond-exp (conditions (list-of expression?)) (actions (list-of expression?)))
)

(define-datatype expval expval?
 (num-val (num number?))
 (bool-val (bool boolean?))
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
     (equal?-exp (left right)
      (let* ([val1 (value-of left env)]
             [val2 (value-of right env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (equal? num1 num2) (bool-val #t) (bool-val #f))
      )
     )
     (less?-exp (left right)
      (let* ([val1 (value-of left env)]
             [val2 (value-of right env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (< num1 num2) (bool-val #t) (bool-val #f))
      )
     )
     (greater?-exp (left right)
      (let* ([val1 (value-of left env)]
             [val2 (value-of right env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (> num1 num2) (bool-val #t) (bool-val #f))
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
     (cond-exp (conditions actions)
       (apply-cond conditions actions env)
     )
    (else (eopl:error "error type to value-of"))    
  )
 ) 
)

(define apply-cond
 (lambda (conditions actions env)
   (cond
     [(null? conditions) (eopl:error "no cond tests succeed")]
     [else
       (let* ([val (value-of (car conditions) env)]
              [value (expval->bool val)]
             )
        (if value
           (value-of (car actions) env)
           (apply-cond (cdr conditions) (cdr actions) env)
        )
      )
     ]
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
     (cond-exp (conditions actions)
      (cond-exp
       (map (lambda (condition) (translation-of condition env)) conditions)
       (map (lambda (action) (translation-of action env)) actions)
      ) 
     )
     (proc-exp (var body)
      (nameless-proc-exp (translation-of body (extend-senv var env)))
     )
     (call-exp (left right)
      (call-exp (translation-of left env) (translation-of right env))
     )
     (greater?-exp (left right)
       (greater?-exp (translation-of left env) (translation-of right env))
     )
     (equal?-exp (left right)
       (equal?-exp (translation-of left env) (translation-of right env))
     )
     (less?-exp (left right)
       (less?-exp (translation-of left env) (translation-of right env))
     )
     (else (eopl:error "error type to translation-of "))
   )
 )
)


(define test (run "
               let x = 8
               in cond {equal?(x,6)==> x}
                    {greater?(x,6) ==> -(x,1)}
                    {less?(x,6) ==> -(x,-1)}  end
"))