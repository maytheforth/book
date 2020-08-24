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

(define (mark-leaves-with-red-depth bintree)
(define (helper bintree depth)
 (if (leaf? bintree)
     (leaf depth)
     (if (equal? (contents-of bintree) `red)
      (cons (contents-of bintree) (cons (helper (lson bintree) (+ depth 1))(helper (rson bintree) (+ depth 1))))
      (cons (contents-of bintree) (cons (helper (lson bintree) depth)(helper (rson bintree) depth)))
     )
 )
)
(helper bintree 0)
)

(define bintree1 (interior-node `red (interior-node `bar (leaf 26) (leaf 12)) (interior-node `red (leaf 11) (interior-node `quux (leaf 117)(leaf 14)))))