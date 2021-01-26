(import curl)

(defn fetch-print
  "Simple url fetch. Prints response to the stdout.
  Parameter should be table with structure as
  returned by the parse-requests fn.\n
  Throws error when fetch fails"
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

(defn parse-requests
  "Parses src string as request specification.
  Returns array with all the parsed requests
  as tables."
  [src]

  (var common-headers [])
  (defn collect-headers [x] (seq [i :in x :when (i :header)] (i :header)))
  (defn pdefs [& x] (set common-headers (collect-headers x)))
  (defn preq []
    (fn [& x]
      (-> {:headers (collect-headers x)}
          (merge ;x)
          (put :header nil)
          (update :headers array/concat common-headers))))
  (defn pnode [tag] (fn [& x] {tag ;x}))

  (def request-grammar
    (peg/compile
      ~{:eol "\n"
        :header (* (/ '(* :w (to ":") ": " (to :eol)) ,(pnode :header)) :eol)
        :definitions (* (/ (* "#" (thru :eol) (some :header)) ,pdefs) :eol)
        :title (* (/ (line) ,(pnode :start)) (/ (* "#" (/ '(to :eol) ,string/trim) :eol) ,(pnode :title)))
        :method (/ (* '(+ "GET" "POST" "PATCH" "DELETE")) ,(pnode :method))
        :url (/ (* '(to :eol)) ,(pnode :url))
        :command (* :method " " :url :eol)
        :body (/ (* :eol (not "#")
                    '(some (if-not (* "\n" (+ -1 "\n")) 1)))
                 ,(pnode :body))
        :request (/ (* :title :command (any :header) (any :body) (/ (line) ,(pnode :end)) (+ -1 "\n"))
                    ,(preq))
        :main (* (drop :definitions) (some :request))}))

  (:match request-grammar src))

(defn main
  "Program entry point. If called without params,
   it parses standart input and execute all
   requests specified in it.\nIf parameter line
   is provided, only request containing the specified
   line is executed.\nIf file parameter is given
   the program reads from the file instead of stdin.\n
   Throws error when line is not nunmber."
  [_ &opt line file]

  (def src (if file (file/open file) stdin))
  (def requests (parse-requests (:read src :all)))

  (if line
    (if-let [i (scan-number line)]
      (->> requests
           (find |(<= ($ :start) i ($ :end)))
           (fetch-print))
      (error (string "Line must be a nuber, got: " line)))
    (loop [r :in requests] (fetch-print r))))
