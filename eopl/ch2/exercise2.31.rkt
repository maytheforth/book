#lang eopl
; Prefix-list ::= (Prefix-exp)
; Prefix-exp ::= Int
;            ::= - Prefix-exp Prefix-exp

(define-datatype prefix-exp prefix-exp?
  (const-exp (num integer?))
  (diff-exp
   (operand1 prefix-exp?)
   (operand2 prefix-exp?)
  )
)

(define parse-prefix-exp
 (lambda(prefix-list)
  (let ([head (car prefix-list)]
        [tail (cdr prefix-list)]
       )
    (cond 
      [(integer? head) (cons (const-exp head) tail)]
      [(equal? head `-)(
         let* ([operand-1-and-rest-1 (parse-prefix-exp tail)]
               [operand-1 (car operand-1-and-rest-1)]
               [rest-1 (cdr operand-1-and-rest-1)]
               [operand-2-and-rest-2 (parse-prefix-exp rest-1)]
               [operand-2 (car operand-2-and-rest-2)]
               [rest-2 (cdr operand-2-and-rest-2)])
          (cons (diff-exp operand-1 operand-2) rest-2)
      )]
      [else (display "error syntax")]
    )
  )
 )
)

(define parse-prefix-list
 (lambda (prefix-list)
   (let* ([exp-and-rest (parse-prefix-exp prefix-list)]
          [exp (car exp-and-rest)]
          [rest(cdr exp-and-rest)]
         )
     (if (null? rest)
         exp
        (display "error syntax")
     )
   )
 )
)


(define x (list `- `- 3 2 `- 4 `- 12 7))
(define y (parse-prefix-list x))