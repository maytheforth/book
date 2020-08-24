#lang racket
(define leaf
(lambda (num)
 num
)
)

(define interior-node
(lambda (symbol left-child right-child)
  (cons symbol (cons left-child right-child))
)
)

(define leaf? integer?)
(define lson cadr)
(define rson cddr)

(define contents-of
(lambda (bin-tree)
 (if (leaf? bin-tree)
     bin-tree
     (car bin-tree)
 )
)
)

; helper 返回的是需要求的bintree和下一个n的list
; 右子树的计算需要左子树计算完之后的n
(define (number-leaves bintree)
(define (helper bintree n)
(if (leaf? bintree)
    (cons (leaf n) (+ n 1))
    (let* ([left-result (helper (lson bintree) n)]
     [right-result (helper (rson bintree)(cdr left-result))])
     (cons (interior-node (contents-of bintree)(car left-result)(car right-result))
           (cdr right-result)
     )
    )
 )
)
  (car (helper bintree 0))
)

(define bintree1 (interior-node `red (interior-node `bar (leaf 26) (leaf 12)) (interior-node `red (leaf 11) (interior-node `quux (leaf 117)(leaf 14)))))
