#lang eopl
(define-datatype red-blue-tree red-blue-tree?
  (red-node
   (first red-blue-tree?)
   (second red-blue-tree?)
   )
  (blue-node
   (tlst (list-of red-blue-tree?))
   )
  (leaf-node (num integer?))
)

(define build-tree-helper
 (lambda (tree num)
  (cases red-blue-tree tree
    (red-node (first second) (red-node (build-tree-helper first (+ num 1)) (build-tree-helper second (+ num 1))))
    (blue-node (tlst)
     (if (null? tlst) 
         (blue-node)
         (blue-node (map (lambda (subtree) (build-tree-helper subtree num)) tlst))
     )
    )
    (leaf-node (var) (leaf-node num))
  ) 
 )
)

(define build-tree
(lambda (tree)
  (build-tree-helper tree 0)
)
)

(define tree1 (red-node (leaf-node 1) (leaf-node 2)))
(define tree2 (blue-node (list (leaf-node 1) (red-node (leaf-node 1) (leaf-node 2)) (leaf-node 3))))
(define tree3 (red-node tree2 tree1))
(define answer (build-tree tree3))