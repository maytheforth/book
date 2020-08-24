#lang racket
(define leaf
`()
)

(define interior-node
(lambda (root left-child right-child)
    (cons root (cons left-child right-child))
)
)


(define (path n bintree)
(define (helper n bintree result)
(cond
  [(empty? bintree) (error "can not find result")]
  [(equal? n (car bintree)) result]
  [(< n (car bintree)) (helper n (cadr bintree) (append result (list "left")))]
  [else (helper n (cddr bintree) (append result (list "right")))]
)
)
(helper n bintree empty)
)

(define bintree1
(interior-node 14 (interior-node 7 leaf (interior-node 12 leaf leaf)) (interior-node 26 (interior-node 20 (interior-node 17 leaf leaf) leaf) (interior-node 31 leaf leaf)))
)

(path 17 bintree1)