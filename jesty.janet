(import uri)
(import curl)
(import json)

(defn render-url [r]
  (def url (r :url))
  (string (url :scheme) "://" (url :host) ":" (url :port) (url :path) "?" (url :raw-query)))

(defn fetch
  "Simple url fetch. Returns string with the content of the resource."
  [request]
  (def c (curl/easy/init))
  (def b (buffer))
  (:setopt c
           :url (render-url request)
           :write-function (fn [buf] (buffer/push-string b buf))
           :no-progress? true)
  (when-let [headers (request :headers)]
    (:setopt c :http-header headers))
  (case (request :method)
    "POST" (:setopt c
                    :post? true
                    :post-fields (request :body)
                    :post-field-size (length (request :body)))
    "PATCH" (:setopt c
                     :custom-request "PATCH"
                     :post-fields (request :body)
                     :post-field-size (length (request :body))))
  (:perform c)
  b)

(def request-grammar
  {:title ~(* (constant :title) (? "\n") "#" (cmt '(some (if-not "\n" 1)) ,string/trim) "\n")
   :method '(* (constant :method) '(+ "GET" "POST" "PATCH"))
   :command ~(* :method " " (* (constant :url) (cmt '(some (if-not "\n" 1)) ,uri/parse)) "\n")
   :header '(* (constant :header) '(* (some (+ :w "-")) ": " (some (if-not "\n" 1))) "\n")
   :body '(* "\n" (not "#") (* (constant :body) '(some (if-not (+ (* "\n#") -1) 1))))
   :request '(* (constant :request) :title :command (any :header) (any :body))
   :main '(some :request)})

(defn parse-requests [src]
  (def commands (peg/match request-grammar src))
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
    (let [r (requests (scan-number i))]
      (tracev (json/decode (fetch r) true)))
    (each r requests
      (tracev (fetch r)))))
