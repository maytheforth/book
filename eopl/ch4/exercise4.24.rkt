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
    (comment ("//" (arbno (not #\newline))) skip)
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
 '((program (statement) a-program)
   (statement (identifier "=" expression) assign-stmt)
   (statement ("print" expression) print-stmt)
   (statement ("{" statement (arbno ";" statement )"}") block-stmt)
   (statement ("if" expression statement statement ) if-stmt)
   (statement ("while" expression statement) while-stmt)
   (statement ("var" identifier (arbno "," identifier) ";" statement ) declare-stmt)
   (statement ("read" identifier) read-stmt)
   (statement ("do" statement "while" expression) do-while-stmt)
   (expression (identifier) var-exp)
   (expression (number) const-exp)
   (expression ("-" "(" expression "," expression ")") diff-exp)
   (expression ("+" "(" expression "," expression ")") add-exp)
   (expression ("*" "(" expression "," expression ")") multiply-exp)
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
   (expression ("not" "(" expression ")") not-exp)
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
   (expression ("begin" expression (arbno ";" expression) "end") begin-exp)
   (expression ("letrec" (arbno identifier "(" (separated-list identifier ",") ")" "=" expression ) "in" expression) letrec-exp)
   (expression ("set" identifier "=" expression) assign-exp)
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

; return (reflist new-store)
(define newref-list
 (lambda (store vallist)
   (cond
     [(null? vallist) (eopl:error "vallist should not be null")]
     [(equal? (length vallist) 1)
      (let* ([rest (newref store (car vallist))]
             [rest-ref (car rest)]
             [rest-store (cdr rest)]
            )
        (cons (list rest-ref) rest-store)
      )
     ]
     [else
       (let* ([rest-left (newref-list store (list (car vallist)))]
              [rest-left-list (car rest-left)]
              [rest-left-store (cdr rest-left)]
              [rest-right (newref-list rest-left-store (cdr vallist))]
              [rest-right-store (cdr rest-right)]
              [rest-right-list (car rest-right)]
             )
          (cons (append rest-left-list rest-right-list) rest-right-store)
       )
     ]
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

(define setref!-list
 (lambda (store reflist vallist)
  (cond
    [(null? reflist) (eopl:error "error, reflist should not be null")]
    [(equal? (length reflist) 1) (setref! store (car reflist) (car vallist))]
    [else
      (let* ([rest (setref! store (car reflist) (car vallist))]
             [rest-store (cdr rest)]
            )
        (setref!-list rest-store (cdr reflist) (cdr vallist))
      )
   ]
  )
 )
)

;------------------------------------------define env
(define-datatype environment environment?
 (empty-env)
 (extend-env
   (var (lambda (var)
     (or (symbol? var) ((list-of symbol?) var))
     )
   ) 
   (val (lambda (val)
        (or (reference? val) ((list-of reference?) val))
    )
   )
   (env environment?)
  )
)


;(define extend-env-rec
; (lambda (p-name b-var body saved-env)
;   (let ([vec (make-vector 1)])
;     (let ([new-env (extend-env p-name vec saved-env)])
;       (vector-set! vec 0 (proc-val (procedure b-var body new-env #f)))
;       new-env
;     )
;   )
; )
;)

(define extend-env-rec
 (lambda (p-names b-vars bodies saved-env store)
   (let* ([vals (map (lambda (bound-var proc-body) (proc-val (procedure bound-var proc-body saved-env #f))) b-vars bodies)]
          [rest (newref-list store vals)]
          [rest-list (car rest)]
          [rest-store (cdr rest)]
          [new-env (extend-env p-names rest-list saved-env)]
          [new-vals (map (lambda (bound-var proc-body) (proc-val (procedure bound-var proc-body new-env #f))) b-vars bodies)]
          [new-store (cdr (setref!-list rest-store rest-list new-vals))]
          )
      (cons new-env new-store)
   )
 )
)

(define proc-search
 (lambda (varlist search-val index)
   (cond
     [(null? varlist) #f]
     [(equal? (car varlist) search-val) index]
     [else (proc-search (cdr varlist) search-val (+ 1 index))]
   )
 )
)




(define apply-env
 (lambda (env search-var)
   (cases environment env
     (empty-env () (display "error, found no such var"))
     (extend-env (saved-var saved-val saved-env)
       (cond
          [(list? saved-var)
            (let ([ret (proc-search saved-var search-var 0)])
              (if (equal? ret #f)
                (apply-env saved-env search-var)
                ret
              )
            )
          ]
          [else
            (if (equal? saved-var search-var)
                saved-val
                (apply-env saved-env search-var)
            )
          ]
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
  (a-program (stmt statement?))
)


(define-datatype expression expression?
 (const-exp (num number?))
 (diff-exp (exp1 expression?) (exp2 expression?))
 (add-exp (exp1 expression?) (exp2 expression?))
 (multiply-exp (exp1 expression?) (exp2 expression?))
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
 (begin-exp (first expression?) (second (list-of expression?)))
 (letrec-exp (p-names (list-of symbol?)) (bound-vars (list-of (list-of symbol?))) (p-bodies (list-of expression?)) (letrec-body expression?))
 (assign-exp (var symbol?) (body expression?))
 (not-exp (exp expression?))
)

(define-datatype statement statement?
 (assign-stmt (var symbol?) (body expression?))
 (print-stmt (body expression?))
 (block-stmt (first-stmt statement?)(bodies (list-of statement?)))
 (if-stmt (exp1 expression?) (body1 statement?) (body2 statement?))
 (while-stmt (exp1 expression?)(body statement?))
 (declare-stmt (first-var symbol?)(vars (list-of symbol?)) (body statement?))
 (read-stmt (var symbol?))
 (do-while-stmt (body statement?) (exp1 expression?))
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

(define expval->printable
 (lambda (exp)
   (cases expval exp
     (ref-val (ref) (string-append "reference:" (number->string ref)))
     (num-val (num) num)
     (bool-val (bool) bool)
     (emptylist-val () empty)
     (proc-val (proc) "procedure")
     (pair-val (left right) (cons (expval->printable left) (expval->printable right)))
     (else "wrong type")
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
   (cases program pgm
     (a-program (stmt) (result-of stmt (init-env) (empty-store)))
   )
 )
)

(define apply-store
 (lambda (store ref)
  (if (null? store) 
      (eopl:error "error , invalid reference")
      (deref store ref)
  )
 )
)


(define value-of
 (lambda (exp env store)
  (cases expression exp
    (const-exp (num) (an-answer (num-val num) store))
    (var-exp (var) (an-answer (apply-store store (apply-env env var)) store))
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
    (add-exp (exp1 exp2)
      (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (num-val (+ num1 num2)) store2)
             )
           )
         )
       )
      )
    )
    (multiply-exp (exp1 exp2)
      (cases answer (value-of exp1 env store)
        (an-answer (val1 store1)
         (cases answer (value-of exp2 env store1)
           (an-answer (val2 store2)
             (let* ([num1 (expval->num val1)]
                    [num2 (expval->num val2)]
                   )
                (an-answer (num-val (* num1 num2)) store2)
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
         (let* ([rest (newref new-store val1)]
                [rest-ref (car rest)]
                [rest-store (cdr rest)]
               )
            (value-of body (extend-env var rest-ref env) rest-store)
         )
         ; (value-of body (extend-env var val1 env) new-store)
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
      (an-answer (proc-val (procedure vars body env #f)) store)
    )
    (traceproc-exp (vars body)
      (an-answer (proc-val (procedure vars body env #t)) store)
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
    (begin-exp (first second)
      (let* ([rest (apply-begin (append (list first) second) env store)]
             [rest-val (car rest)]
             [rest-store (cdr rest)]
            )
         (an-answer rest-val rest-store)
      )
    )
    (assign-exp (var body)
     (cases answer (value-of body env store)
       (an-answer (v1 store1)
        (let* ([var-ref (apply-env env var)]
               [rest (setref! store1 var-ref v1)]
              )
          (an-answer (car rest) (cdr rest))
        )
       )
     )
    )
   (letrec-exp (p-names bound-vars p-bodies letrec-body)
     (let* ([rest (extend-env-rec p-names bound-vars p-bodies env store)]
            [rest-env (car rest)]
            [rest-store (cdr rest)])
       (value-of letrec-body rest-env rest-store)
    )
   )
    (not-exp (exp)
     (cases answer (value-of exp env store)
      (an-answer (v1 store1)
        (let ([val (expval->bool v1)])
           (an-answer (bool-val (not val))store1)
        )
      )
     )
   )
 )
)
)

; a statement does not return a value, but acts by modifying the store and by printing
; (result-of stmt env store) = store1
(define result-of
 (lambda (stmt env store)
  (cases statement stmt
    (print-stmt (body)
     (cases answer (value-of body env store)
      (an-answer (v1 store1)
          (display (expval->printable v1))
          (display "\n")
           store1
      )
     )
    )
    (declare-stmt (first-var vars body)
      (let* ([vallist (map (lambda(number) (num-val 0)) (append (list first-var) vars))]
             [rest (newref-list store vallist)]
             [rest-list (car rest)]
             [rest-store (cdr rest)]
             [new-env (extend-env-with-list (append (list first-var) vars) rest-list env)]
            )
        (result-of body new-env rest-store)
      )
     )
    (assign-stmt (var body)
     (cases answer (value-of body env store)
      (an-answer (v1 store1)
        (let* ([var-ref (apply-env env var)]
               [rest (setref! store1 var-ref v1)]
               [rest-store (cdr rest)]
              )
           rest-store
        )
      )
     )
    )
    (block-stmt (first-stmt bodies)
       (execute-block (append (list first-stmt) bodies) env store)
    )
    (while-stmt (exp body)
       (execute-while exp body env store)
     )
    (if-stmt (exp1 body1 body2)
      (cases answer (value-of exp1 env store)
        (an-answer (v1 store1)
         (if (expval->bool v1)
           (result-of body1 env store1)
           (result-of body2 env store1)
         )
        )
      )
     )
    (read-stmt (var)
     (let ([x (read)])
       (if (< x 0)
         (eopl:error "read-stmt should read a nonnegative integer")
         (let* ([rest (setref! store (apply-env env var) (num-val x))]
                [rest-store (cdr rest)]
               )
            rest-store
         )
       )
     )
    )
    (do-while-stmt (body exp1)
     (let ([new-store (result-of body env store)])
       (execute-while exp1 body env new-store)
     )
    )
    (else (display "nothing"))
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
         (let* ([rest (newref-list store vals)]
               [rest-list (car rest)]
               [rest-store (cdr rest)]
               [x (value-of body (extend-env-with-list vars rest-list saved-env) rest-store)]
               )
           (if flag (display "traceproc exit\n") `())
           x
         )
     )
   )
 )
)


(define apply-begin
  (lambda (exp-list env store)
   (cond
     [(null? exp-list) (eopl:error "apply-begin argument should not be empty")]
     [(equal? (length exp-list) 1)
       (cases answer (value-of (car exp-list) env store)
         (an-answer (val new-store) (cons val new-store))
       )
     ]
     [else
       (cases answer (value-of (car exp-list) env store)
         (an-answer (val new-store)
           (apply-begin (cdr exp-list) env new-store)
         )
       )
     ]
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

(define execute-block
 (lambda (stmt-list env store)
   (cond
     [(null? stmt-list) (eopl:error "stmt-list should not be empty")]
     [(equal? (length stmt-list) 1) (result-of (car stmt-list) env store)]
     [else
      (let ([new-store (result-of (car stmt-list) env store)])
        (execute-block (cdr stmt-list) env new-store)
      )
     ]
   )
  )
 )

(define execute-while
 (lambda (exp body env store)
  (cases answer (value-of exp env store)
   (an-answer (v1 store1)
     (let ([val (expval->bool v1)])
       (if val
         (execute-while exp body env (result-of body env store))
         store
       )
     )
   )
  )
 )
)

;----------------------------------------------- run test


(define test1 (run "print list(1,2,3)"))
(define test2 (run "var x; print x"))
(define test3 (run "var x; x = 100"))
(define test4 (run "var x; {print x}"))
(define test5 (run "var x,y; {x = 100; print x; y = 200; print y}"))
(define test6 (run "var x; {x = 100; if zero?(x) x = +(x,100) x=-(x,101); print x}"))

(define ex1 (run "var x,y; { x =3; y =4; print +(x,y)}"))
(define ex2 (run "var x,y,z; { x = 3;
                               y = 4;
                               z = 0;
                               while not(zero?(x))
                               { z = +(z,y); x = -(x,1)};
                               print z
}"))

(define ex3 (run " var x ; { x = 3;
                         print x;
                         var x; {x = 4; print x};
                         print x}
")
)

(define ex4 (run "var f,x; { f = proc(x,y) *(x,y);
                             x = 3;
                             print (f 4 x)}
"
 )
)

(define ex5 (run "var x,y,z; { x = 3;
                               y = 4;
                               z = 0;
                               do { z = +(z,y); x = -(x,1)}
                               while not(zero?(x));
                               print z
}"))

(define test7 (run "var x; {read x; print x}"))
