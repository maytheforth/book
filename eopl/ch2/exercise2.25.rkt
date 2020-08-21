#lang eopl
(define-datatype bintree bintree?
(leaf-node (num integer?))
(interior-node
 (key symbol?)
 (left bintree?)
 (right bintree?)
)
)

(define leaf-sum
(lambda (tree)
 (cases bintree tree
  (leaf-node (var) var)
  (interior-node (key left right)
   (+ (leaf-sum left) (leaf-sum right))
  )
 )
)
)

(define leaf-node?
(lambda (tree)
 (cases bintree tree
  (leaf-node (var) #t)
  (interior-node (key left right)
     #f
  )
 )
)
)

(define helper
 (lambda (tree)
  (cases bintree tree
    (interior-node (key left right)
      (cond
        [(and (leaf-node? left) (leaf-node? right)) (cons (+ (helper left) (helper right)) key)]
        [(leaf-node? left) (if (< (car (helper right)) (leaf-sum tree)) (cons (leaf-sum tree) key) (helper right))]
        [(leaf-node? right)(if (< (car (helper left)) (leaf-sum tree)) (cons (leaf-sum tree) key) (helper left))]
        [else
         (let* ([x (helper left)]
                [y (helper right)]
               )
           (if (> (car x) (car y))
               (if (> (car x) (leaf-sum tree)) x (cons (leaf-sum tree) key))
               (if (> (car y) (leaf-sum tree)) y (cons (leaf-sum tree) key))
           )
         )
        ]
      )     
    )
    (leaf-node (var) var)
  )
 )
)

(define max-interior
(lambda (tree)
  (cdr (helper tree))
)
)


(define tree1 (interior-node `foo (leaf-node 2)(leaf-node 3)))
(define tree2 (interior-node `bar (leaf-node -1) tree1))
(define tree3 (interior-node `baz tree2 (leaf-node 2)))
(define tree4 (leaf-node 1))









