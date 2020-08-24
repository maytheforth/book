#lang racket
(define (count-occurrences s slist)
(cond
[(list? slist)
(if (empty? slist)
 0
 (+ (count-occurrences s (car slist)) (count-occurrences s (cdr slist)))
)
]
[(equal? s slist) 1]
[else 0]
)
)

(count-occurrences "x" `(("f" "x") "y" ((("x" "z")"x"))))
(count-occurrences "x" `(("f" "x") "y" ((("x" "z" () "x")))))
(count-occurrences "w" `(("f" "x") "y" ((("x" "z") "x"))))