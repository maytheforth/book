#lang eopl
; store-passing style
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
   (expression ("(" expression (arbno expression) ")") call-exp)
   ; 3.21 change from single argument to multiple arguments 
   (expression ("proc" "("  (separated-list identifier ",") ")" expression) proc-exp)
   ; 3.27 traceproc
   (expression ("traceproc" "(" (separated-list identifier ",") ")" expression) traceproc-exp)
   (expression ("newref" "(" expression ")") newref-exp)
   (expression ("deref" "(" expression ")") deref-exp)
   (expression ("setref" "(" expression "," expression ")") setref-exp)
  )
)

(define scan&parse (sllgen:make-string-parser scanner grammar-a1))

;-----------------------------------------define store



(define-datatype answer answer?
 (an-answer
   (val expval?)
   (store store?)
 )
)

(define empty-store
 (lambda ()
   `()
 )
)

(define initialize-store!
  (lambda ()
    (empty-store)
  )
)

(define reference?
 (lambda (n)
   (integer? n)
 )
)

(define newref
  (lambda (store saved-value)
     (let* ([new-length (length store)]
           [new-store (append store (list saved-value))])
       (cons new-length new-store)
     )
  )
)

(define deref
 (lambda (store n)
   (if (reference? n)
       (list-ref store n)
       (eopl:error "this is not a reference " n)
   )
 )
)


(define setref-helper
 (lambda (store ref saved-value)
  (cond
    [(null? store) (eopl:error "invalid reference")]
    [(= ref 0) (cons saved-value (cdr store))]
    [else (cons (car store) (setref-helper (cdr store) (- ref 1) saved-value))]
  )
 )
)


; also return (ret new-store), although ret is meaningless
(define setref!
  (lambda (store ref saved-value)
    (cons (num-val 42) (setref-helper store ref saved-value))
  )
)


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


(define extend-env-rec
 (lambda (p-name b-var body saved-env)
   (let ([vec (make-vector 1)])
     (let ([new-env (extend-env p-name vec saved-env)])
       (vector-set! vec 0 (proc-val (procedure b-var body new-env #f)))
       new-env
     )
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
 (equal?-exp (exp1 expression?) (exp2 expression?))
 (greater?-exp (exp1 expression?) (exp2 expression?))
 (less?-exp (exp1 expression?) (exp2 expression?))
 (emptylist-exp)
 (cons-exp (exp1 expression?) (exp2 expression?))
 (car-exp (body expression?))
 (cdr-exp (body expression?))
 (null?-exp (exp expression?))
 (list-exp (args (list-of expression?)))
 (if-exp (exp1 expression?) (exp2 expression?) (exp3 expression?))
 (var-exp (var symbol?))
 (let-exp (var symbol?) (exp1 expression?) (body expression?))
 (proc-exp (args (list-of symbol?)) (body expression?))
 (call-exp (rator expression?) (rand (list-of expression?)))
 (traceproc-exp (args (list-of symbol?)) (body expression?))
 (newref-exp (value expression?))
 (deref-exp (value expression?))
 (setref-exp (ref expression?) (value expression?))
)


(define-datatype expval expval?
 (num-val (num number?))
 (bool-val (bool boolean?))
 (pair-val (car expval?)(cdr expval?))
 (emptylist-val)
 (proc-val (proc proc?))
 (ref-val (ref reference?))
)

(define store?
  (list-of expval?)
)

(define list-val
 (lambda (args env store)
   (if (null? args)
       (cons (emptylist-val) store)
       (cases answer (value-of (car args) env store)
         (an-answer (val new-store)
         (let* ([rest (list-val (cdr args) env new-store)]
                [rest-ret (car rest)]
                [rest-store (cdr rest)]
                )
            (display rest)
            (display "+++++\n")
            (cons (pair-val val rest-ret) rest-store)
         )
         )
       )
   )
 )
)

(define parse-args
  (lambda (args env store)
   (cond
     [(null? args) (cons empty store)]
     [(= (length args) 1)
      (cases answer (value-of (car args) env store)
        (an-answer (val new-store)
           (cons (list val) new-store)
        )
      )
     ]
     [else
       (cases answer (value-of (car args) env store)
         (an-answer (val new-store)
           (let* ([rest (parse-args (cdr args) env new-store)]
                  [rest-ret (car rest)]
                  [rest-store (cdr rest)]
                 )
              (cons (append (list val) rest-ret) rest-store)
           )
         )
       ) 
     ]
   )
 )
)


(define expval->reference
 (lambda (exp)
   (cases expval exp
     (ref-val (ref) ref)
     (else (eopl:error "error type to reference"))
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
   (initialize-store!)
   (cases program pgm
     (a-program (exp1) (value-of exp1 (init-env) (empty-store)))
   )
 )
)

(define value-of
 (lambda (exp env store)
  (cases expression exp
    (const-exp (num) (an-answer (num-val num) store))
    (var-exp (var) (an-answer (apply-env env var) store))
    (diff-exp (exp1 exp2)
      (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (num-val (- num1 num2)) store2)
             )
           )
         )
       )
      )
    )
    (zero?-exp (exp1)
     (cases answer (value-of exp1 env store)
       (an-answer (val1 new-store)
         (let ([num1 (expval->num val1)])
           (if (zero? num1)
             (an-answer (bool-val #t) new-store)
             (an-answer (bool-val #f) new-store)
           )
         )
       )
     )
    )
    (if-exp (exp1 exp2 exp3)
     (cases answer (value-of exp1 env store)
       (an-answer (val new-store)
        (if (expval->bool val)
          (value-of exp2 env new-store)
          (value-of exp3 env new-store)
         )
       )
     )
    )
    (let-exp (var exp1 body)
      (cases answer (value-of exp1 env store)
        (an-answer (val1 new-store)
          (value-of body (extend-env var val1 env) new-store)
        )
      )
    )
    (equal?-exp (exp1 exp2)
     (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (bool-val (equal? num1 num2)) store2)
             )
           )
         )
       )
      )
    )
   (greater?-exp (exp1 exp2)
     (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (bool-val (> num1 num2)) store2)
             )
           )
         )
       )
      )
    )
    (less?-exp (exp1 exp2)
     (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (bool-val (< num1 num2)) store2)
             )
           )
         )
       )
      )
    )
    (emptylist-exp ()
      (an-answer emptylist-val store)
    )
    (cons-exp (exp1 exp2)
      (cases answer (value-of exp1 env store)
         (an-answer (val1 store1)
          (cases answer (value-of exp2 env store1)
            (an-answer (val2 store2)
              (an-answer (pair-val (val1 val2)) store2)
            )
          )
        )
      )
    )
    (car-exp (exp)
     (cases answer (value-of exp env store)
       (an-answer (val new-store)
          (an-answer (expval->car val) new-store)
       )
     )
    )
    (cdr-exp (exp)
      (cases answer (value-of exp env store)
         (an-answer (val new-store)
            (an-answer (expval->cdr val) new-store)
         )
      )
    )
    (null?-exp (exp)
      (cases answer (value-of exp env store)
         (an-answer (val new-store)
            (an-answer (expval->null? val) new-store)
         )
      )
    )
    (list-exp (args)
     (let ([ret (list-val args env store)])
       (an-answer (car ret) (cdr ret))
     )
    )
    (proc-exp (vars body)
      (an-answer (proc-val (procedure vars body env #t)) store)
    )
    (traceproc-exp (vars body)
      (an-answer (proc-val (procedure vars body env #f)) store)
    )
    (call-exp (rator rand)
     (cases answer (value-of rator env store)
       (an-answer (val store1)
         (let* ([proc (expval->proc val)]
                [rest (parse-args rand env store1)]
                [rest-store (cdr rest)]
                [rest-ret (car rest)]
               )
           (apply-procedure proc rest-ret rest-store)
         )
       )
     )
    )
    (newref-exp (val)
     (cases answer (value-of val env store)
       (an-answer (v1 new-store)
        (let* ([ret (newref new-store v1)]
               [ret-ref (car ret)]
               [ret-store (cdr ret)]
              )
          (an-answer (ref-val ret-ref) ret-store)
        )
       )
     )
    )
    (deref-exp (val)
      (cases answer (value-of val env store)
        (an-answer (v1 new-store)
          (let ([ref1 (expval->reference v1)])
             (an-answer (deref new-store ref1) new-store)
          )
        )
      )
    )
    (setref-exp (ref value)
     (cases answer (value-of ref env store)
       (an-answer (v1 store1)
         (cases answer (value-of value env store1)
           (an-answer (v2 store2)
             (let* ([ret (setref! store2 (expval->reference v1) v2)]
                    [ret-ref (car ret)]
                    [ret-store (cdr ret)]
                   )
                (an-answer ret-ref ret-store)
             )
           )
         )
       )
     )         
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
 (lambda (proc1 vals store)
   (cases proc proc1
     ( procedure (vars body saved-env flag)
         (if flag (display "traceproc enter\n") `())
         (let ([x (value-of body (extend-env-with-list vars vals saved-env) store)])
           (if flag (display "traceproc exit\n") `())
           x
         )
     )
   )
 )
)

(define apply-begin
 (lambda (exp-list env)
   (cond
     [(null? exp-list) (eopl:error "apply-begin argument should not be empty")]
     [(equal? (length exp-list) 1) (value-of (car exp-list) env)]
     [else (begin (value-of (car exp-list) env) (apply-begin (cdr exp-list) env))]
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

(define test (run "
          let x = newref(100)
            in list(deref(x), setref(x,12), deref(x))
"))








