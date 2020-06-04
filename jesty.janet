(import curl)
(import json)
(import utf8)

(defn fetch-print
  "Simple url fetch. Returns string with the content of the resource."
  [{:url url :method method :headers headers :body body}]
  (def c (curl/easy/init))
  (:setopt c
           :url url
           :write-function |(print $)
           :no-progress? true)
  (when headers (:setopt c :http-header headers))
  (case method
    "POST" (:setopt c
                    :post? true
                    :post-fields body
                    :post-field-size (length body))
    "PATCH" (:setopt c
                     :custom-request "PATCH"
                     :post-fields body
                     :post-field-size (length body))
    "DELETE" (:setopt c :custom-request "DELETE"))
  (def res (:perform c))
  (when (not (zero? res))
    (error (string "Cannot fetch: " (curl/easy/strerror res)))))

(defn parse-requests [src]
  (var l 1)
  (var ll l)
  (defn mark-start [] (set ll l))

  (defn eol [& _] (++ l))

  (defn collect-headers [x]
    (seq [i :in x
          :when (i :header)]
      (i :header)))

  (defn pdefs [& x]
    (mark-start)
    (collect-headers x))

  (defn preq []
    (fn [& x]
      (def res
        (put (merge {:headers (collect-headers x)
                     :start ll :end (dec l)} ;x) :header nil))
      (mark-start)
      res))

  (defn pnode [tag] (fn [& x] {tag ;x}))

  (def request-grammar
    {:eol ~(drop (cmt '"\n" ,eol))
     :header ~(/ (* '(* (some (+ :w "-")) ": " (some (if-not "\n" 1))) :eol) ,(pnode :header))
     :definitions ~(/ (* "# definitions" :eol (some :header) :eol) ,pdefs)
     :title ~(/ (* "#" (/ '(some (if-not "\n" 1)) ,string/trim) :eol) ,(pnode :title))
     :method ~(/ (* '(+ "GET" "POST" "PATCH" "DELETE")) ,(pnode :method))
     :url ~(/ (* '(some (if-not "\n" 1))) ,(pnode :url))
     :command '(* :method " " :url :eol)
     :body ~(/ (* :eol (not "#") (* '(some (if-not (* "\n" (+ -1 "\n")) (+ :eol 1))) :eol)) ,(pnode :body))
     :request ~(/ (* :title :command (any :header) (any :body) (+ -1 "\n")) ,(preq))
     :main ~(* (? :definitions) (/ (some :request) ,tuple))})

  (def [defs reqs] (peg/match request-grammar src))
  (map |(update $ :headers array/concat defs) reqs))

(defn main [_ &opt i]
  (def requests (parse-requests (:read stdin :all)))

  (if-let [i (and i (scan-number i))]
    (->> requests
         (find |(<= ($ :start) i ($ :end)))
         (fetch-print))
    (loop [r :in requests] (fetch-print r))))
