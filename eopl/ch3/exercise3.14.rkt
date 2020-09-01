#lang eopl
(define run
 (lambda (string)
   (value-of-program (scan&parse string))
 )
)

(define value-of-program
 (lambda (pgm)
   (cases program pgm
      (a-program (exp1)
        (value-of exp1 (init-env))
      )
      (b-program (exp1)
        (value-of exp1 (init-env))
      )
   )
 )
)


(define-datatype program program?
  (a-program (exp1 expression?))
  (b-program (exp1 bool-expression?))
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
   (program (bool-expression) b-program)
   (expression (identifier) var-exp)
   (expression (number) const-exp)
   (expression ("-" "(" expression "," expression ")") diff-exp)
   (bool-expression ("zero?" "(" expression ")") zero?-exp)
   (bool-expression ("equal?" "(" expression "," expression ")") equal?-exp)
   (bool-expression ("greater?" "(" expression "," expression ")") greater?-exp)
   (bool-expression ("less?" "(" expression "," expression ")") less?-exp)
   (expression ("if" bool-expression "then" expression "else" expression) if-exp)
   (expression ("let" identifier "=" expression "in" expression) let-exp)
  )
)

(define scan&parse (sllgen:make-string-parser scanner grammar-a1))

(define-datatype expression expression?
 (const-exp (num number?))
 (diff-exp (exp1 expression?) (exp2 expression?))
 (if-exp (exp1 bool-expression?) (exp2 expression?) (exp3 expression?))
 (var-exp (var symbol?))
 (let-exp (var symbol?) (exp1 expression?) (body expression?))
)

(define-datatype bool-expression bool-expression?
 (zero?-exp (exp1 expression?))
 (equal?-exp (exp1 expression?) (exp2 expression?))
 (greater?-exp (exp1 expression?) (exp2 expression?))
 (less?-exp (exp1 expression?) (exp2 expression?))
)




(define-datatype expval expval?
 (num-val (num number?))
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

; apply-env
(define apply-env
 (lambda (env search-var)
   (env search-var)
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

(define value-of
 (lambda (exp env)
   (if (expression? exp)
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
     (if-exp (exp1 exp2 exp3)
       (let ([val1 (value-of exp1 env)])
         (if (equal? (expval->num val1) 0)
             (value-of exp3 env)
             (value-of exp2 env)
         )
       )
      )
     (let-exp (var exp1 body)
        (let ([val1 (value-of exp1 env)])
          (value-of body (extend-env var val1 env))
        )
     )
  )
  (cases bool-expression exp
     (zero?-exp (exp1)
       (let* ([val1 (value-of exp1 env)]
              [num1 (expval->num val1)]
              )
         (if (zero? num1) (num-val 1) (num-val 0))
       )
     )
    (equal?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (= num1 num2) (num-val 1) (num-val 0))
      )
    )
    (greater?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (> num1 num2) (num-val 1) (num-val 0))
      )
    )
    (less?-exp (exp1 exp2)
      (let* ([val1 (value-of exp1 env)]
             [val2 (value-of exp2 env)]
             [num1 (expval->num val1)]
             [num2 (expval->num val2)]
            )
        (if (< num1 num2) (num-val 1) (num-val 0))
      )
    )
  )
  )
 ) 
)


(define x (run "let x = 0 in if zero?(x) then -(x,1) else -(x,-1)
"))

(define y (run "zero?(5)"))

(define x1 (run "let x = 0 in if equal?(x,0) then -(x,1) else -(x,-1)"))

(define x2 (run "let x = 0 in if greater?(x,0) then -(x,1) else -(x,-1)"))

(define x3 (run "let x = 0 in if less?(x,0) then -(x,1) else -(x,-1)"))
