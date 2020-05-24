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
  (def res (:perform c))
  (when (not (zero? res))
    (error (string "Cannot fetch: " (curl/easy/strerror res))))
  b)

(var l 1)
(var ll l)
(defn eol [& x] (++ l))

(defn collect-headers [x]
  (->> x
       (filter |($ :header))
       (map |($ :header))))

(defn pdefs [& x]
  (set ll l)
  {:definitions (collect-headers x)})

(defn preq []
  (fn [& x]
    (def res
      (put (merge {:headers (collect-headers x)
                   :start ll :end (dec l)} ;x) :header nil))
    (set ll l)
    res))

(defn preqs [& x] {:requests x})

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
   :main ~(* (? :definitions) (/ (some :request) ,preqs))})

(defn parse-requests [src]
  (def p (merge ;(peg/match request-grammar src)))
  (map |(update $ :headers array/concat (p :definitions))
       (p :requests)))

(defn by-line [i rs]
  (var res nil)
  (loop [r :in rs]
    (if (< (r :start) i)
      (set res r)
      (break)))
  res)

(defn main [_ file &opt i]
  (def src (slurp file))
  (def requests (parse-requests src))

  (if-let [i (and i (scan-number i))]
    (print (fetch (by-line i requests)))
    (loop [r :in requests] (print (r :title)))))
