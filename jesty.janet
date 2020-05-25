(import uri)
(import curl)
(import json)
(import utf8)

(defn fetch
  "Simple url fetch. Returns string with the content of the resource."
  [request]
  (def c (curl/easy/init))
  (def b (buffer))
  (def url (request :url))
  (def u (string (url :scheme) "://" (url :host) ":" (url :port)
                 (url :path)
                 (if (url :query) (string "?" (url :raw-query)) "")))
  (print u)

  (:setopt c
           :url u
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
  (def res (:perform c))
  (when (not (zero? res))
    (error (string "Cannot fetch: " (curl/easy/strerror res))))
  b)

(defn parse-requests [src]
  (var l 1)
  (var ll l)

  (defn eol [& _] (++ l))

  (defn collect-headers [x]
    (seq [i :in x
          :when (i :header)]
      (i :header)))

  (defn pdefs [& x]
    (set ll l)
    (collect-headers x))

  (defn preq []
    (fn [& x]
      (def res
        (put (merge {:headers (collect-headers x)
                     :start ll :end (dec l)} ;x) :header nil))
      (set ll l)
      res))

  (defn pnode [tag] (fn [& x] {tag ;x}))

  (def request-grammar
    {:eol ~(drop (cmt '"\n" ,eol))
     :header ~(/ (* '(* (some (+ :w "-")) ": " (some (if-not "\n" 1))) :eol) ,(pnode :header))
     :definitions ~(/ (* "# definitions" :eol (some :header) :eol) ,pdefs)
     :title ~(/ (* "#" (/ '(some (if-not "\n" 1)) ,string/trim) :eol) ,(pnode :title))
     :method ~(/ (* '(+ "GET" "POST" "PATCH")) ,(pnode :method))
     :url ~(/ (* (/ '(some (if-not "\n" 1)) ,uri/parse)) ,(pnode :url))
     :command '(* :method " " :url :eol)
     :body ~(/ (* :eol (not "#") (* '(some (if-not (* "\n" (+ -1 "\n")) 1)) :eol)) ,(pnode :body))
     :request ~(/ (* :title :command (any :header) (any :body) (+ -1 "\n")) ,(preq))
     :main ~(* (? :definitions) (/ (some :request) ,tuple))})

  (def [defs reqs] (peg/match request-grammar src))
  (map |(update $ :headers array/concat defs) reqs))

(defn print-data [data &opt ind]
  (default ind 0)
  (defn indent [] (for i 0 ind (prin " ")))
  (if (number? data)
    (print data)
    (match [(type data) (empty? data)]
      [:string false] (print data)
      [:string true] (print "\"\"")
      [:table true] (print "{}")
      [:table false]
      (do
        (when (> ind 1) (print))
        (indent)
        (print "{")
        (eachk k data
          (indent)
          (prin "\"" k "\": ")
          (print-data (data k) (+ 2 ind)))
        (indent)
        (print "}"))
      [:array true] (print "[]")
      [:array false]
      (do
        (print)
        (indent)
        (print "[")
        (each v data
          (indent)
          (print-data v (+ 2 ind)))
        (indent)
        (print "]"))
      (print "null"))))

(defn main [_ file &opt i]
  (def src (slurp file))
  (def requests (parse-requests src))

  (if-let [i (and i (scan-number i))]
    (do
      (def res (->> requests
                    (find |(<= ($ :start) i ($ :end)))
                    (fetch)))
      (def data (if-let [{"data" data} (json/decode res false true)] data res))
      (print-data data))
    (loop [r :in requests] (print (r :title)))))
