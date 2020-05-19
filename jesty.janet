(import uri)
(import curl)

(defn fetch
  "Simple url fetch. Returns string with the content of the resource."
  [url]
  (let [c (curl/easy/init)
        b (buffer)]
    (:setopt c
             :url url
             :write-function (fn [buf] (buffer/push-string b buf))
             :no-progress? true)
    (:perform c)
    b))

(def g
  {:title ~(* (constant :title) (? "\n") "#" (cmt '(some (if-not "\n" 1)) ,string/trim) "\n")
   :method '(* (constant :method) '(+ "GET" "POST"))
   :command ~(* :method " " (* (constant :url) (cmt '(some (if-not "\n" 1)) ,uri/parse)) "\n")
   :header '(* (constant :header) '(* (some (+ :w "-")) ": " (some (if-not "\n" 1))) "\n")
   :body '(* "\n" (not "#") (* (constant :body) '(some (if-not (+ (* "\n#") -1) 1))))
   :request '(* (constant :request) :title :command (any :header) (any :body))
   :main '(some :request)})

(defn parse-requests [src]
  (def commands (peg/match g src))
  (def res @[])
  (array/remove commands 0)
  (while (not (empty? commands))
    (def next-req (find-index |(= :request $) commands))
    (def a (reverse (array/slice commands 0 next-req)))
    (def req @{:headers @[]})
    (while (not (empty? a))
      (def n (array/pop a))
      (def v (array/pop a))
      (if (= :header n)
        (update req :headers |(array/push $ v))
        (put req n v)))
    (array/push res req)
    (array/remove commands 0 (if next-req (inc next-req) (length commands))))
  res)

(defn main [_ file &opt i]
  (def src (slurp file))
  (def requests (parse-requests src))
  (if i
    (print (get-in requests [(scan-number i) 1]))
    (each r requests (tracev r))))
