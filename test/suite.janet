# Please take note, that the placeholder api service can be slow on POST,
# so jpm test can take long time to run
# @todo add simple test server

(import test/helper :prefix "" :exit true)

(import ../jesty :as j)

(def og @"")
(with-dyns [:out og] (j/main "jesty" "4" "test/input.http"))
(assert (deep= og @"{\n  \"userId\": 1,\n  \"id\": 1,\n  \"title\": \"delectus aut autem\",\n  \"completed\": false\n}\n") "Bad fetch")

(def op @"")
(with-dyns [:out op] (j/main "jesty" "9" "test/input.http"))
(assert (deep= op @"{\n  \"title\": \"Hello\",\n  \"id\": 101\n}\n") "Bad fetch")
