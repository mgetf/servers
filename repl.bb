#!/usr/bin/env bb
(require '[babashka.nrepl-client :as nrepl])
(nrepl/eval-expr {:port 1337 :expr "(+ 1 2 3)" :host "207.148.8.180"})
;; => {:vals ["6"]}
