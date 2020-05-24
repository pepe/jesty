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

(defn collect-headers [x]
  (map |($ :header) (filter |($ :header) x)))

(defn pdefs [& x] {:definitions (collect-headers x)})

(defn preq []
  (fn [& x]
    (put (merge {:headers (collect-headers x)} ;x) :header nil)))

(defn preqs [] (fn [& x] {:requests x}))

(defn pnode [tag]
  (fn [& x] {tag ;x}))

(var l 0)
(defn eol [& x] (++ l))

(def request-grammar
  {:eol ~(cmt "\n" ,eol)
   ':definitions ~(/ (* "# definitions" :eol (some :header) (? "\n")) ,pdefs)
   :title ~(/ (* (? "\n") "#" (cmt '(some (if-not "\n" 1)) ,string/trim) "\n") ,(pnode :title))
   :method ~(/ (* '(+ "GET" "POST" "PATCH")) ,(pnode :method))
   :url ~(/ (* (/ '(some (if-not "\n" 1)) ,uri/parse)) ,(pnode :url))
   :command '(* :method " " :url "\n")
   :header ~(/ (* '(* (some (+ :w "-")) ": " (some (if-not "\n" 1))) "\n") ,(pnode :header))
   :body ~(/ (* "\n" (not "#") (* '(some (if-not (+ (* "\n#") -1) 1)))) ,(pnode :body))
   :request ~(/ (* :title :command (any :header) (any :body)) ,(preq))
   :main ~(* (? :definitions) (/ (some :request) ,(preqs)))})

(defn parse-requests [src]
  (def p (merge ;(peg/match request-grammar src)))
  (tracev p)
  (map |(update $ :headers array/concat (p :definitions))
       (p :requests)))

(defn main [_ file &opt i]
  (def src (slurp file))
  (def requests (parse-requests src))
  (if-let [i (scan-number i)]
    (tracev (fetch (requests i)))
    (tracev requests)))
