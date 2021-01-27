(import http)

(defn fetch-print
  ```
  Simple url fetch. Prints response to the stdout.
  Parameter should be table with structure as
  returned by the parse-requests fn.
  Throws error when fetch fails
  ```
  [{:url url :method method :headers headers :body body}]

  (print
    ((http/request method url {:headers headers :body body}) :body)))

(defn parse-requests
  ```
  Parses src string as request specification.
  Returns array with all the parsed requests as tables.
  ```
  [src]

  (var common-headers [])
  (defn collect-headers [x]
    (merge ;(seq [i :in x :when (i :header)] (i :header))))
  (defn pdefs [& x] (set common-headers (collect-headers x)))
  (defn preq []
    (fn [& x]
      (-> {:headers (collect-headers x)}
          (merge ;x)
          (put :header nil)
          (update :headers merge common-headers))))
  (defn pnode [tag] (fn [& x] {tag ;x}))

  (def request-grammar
    (peg/compile
      ~{:eol "\n"
        :header (* (/ (/ (* '(* :w (to ":")) ": " '(to "\n")) ,struct)
                      ,(pnode :header)) :eol)
        :definitions (* (/ (* "#" (thru :eol) (some :header)) ,pdefs) :eol)
        :title (* (/ (line) ,(pnode :start))
                  (/ (* "#" (/ '(to :eol) ,string/trim) :eol) ,(pnode :title)))
        :method (/ (* '(+ "GET" "POST" "PATCH" "DELETE")) ,(pnode :method))
        :url (/ (* '(to :eol)) ,(pnode :url))
        :command (* :method " " :url :eol)
        :body (/ (* :eol (not "#")
                    '(some (if-not (* "\n" (+ -1 "\n")) 1)))
                 ,(pnode :body))
        :request (/ (* :title :command (any :header) (any :body)
                       (/ (line) ,(pnode :end)) (+ -1 "\n"))
                    ,(preq))
        :main (* (drop :definitions) (some :request))}))
  (:match request-grammar src))

(defn main
  ```
  Program entry point. If called without params,
  it parses standart input and execute all
  requests specified in it. If parameter line is provided,
  only request containing the specified line is executed.
  If file parameter is given the program reads from the file
  instead of stdin.
  Throws error when line is not nunmber.
  ```
  [_ &opt line file]

  (def requests
    (defer (if file (:close file))
      (def src (if file (file/open file) stdin))
      (parse-requests (:read src :all))))

  (if line
    (if-let [i (scan-number line)]
      (->> (tracev requests)
           (find |(<= ($ :start) i ($ :end)))
           (fetch-print))
      (error (string "Line must be a nuber, got: " line)))
    (loop [r :in requests] (fetch-print r))))
