#lang eopl
(define-datatype bintree bintree?
 (leaf-node (num integer?))
 (interior-node
  (key symbol?)
  (left bintree?)
  (right bintree?)
 )
)

(define tree (interior-node `a (leaf-node 3) (leaf-node 5)))

(define bintree-to-list
(lambda (tree)
( cases bintree tree
 (leaf-node (var) (list `leaf-node var))
 (interior-node (key left right)
  (list `interior-node key (bintree-to-list left) (bintree-to-list right))
 )
)
)
)

(bintree-to-list tree)