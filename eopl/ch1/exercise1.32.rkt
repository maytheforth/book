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

(define (double bintree)
 (if (leaf? bintree)
     (* 2 (contents-of bintree))
     (cons (contents-of bintree) (cons (double (lson bintree))(double (rson bintree))))
 )
)

(define bintree1 (interior-node `red (interior-node `bar (leaf 26) (leaf 12)) (interior-node `red (leaf 11) (interior-node `quux (leaf 117)(leaf 14)))))