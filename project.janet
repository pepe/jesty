(declare-project
  :name "jesty"
  :description "Janet REST client based on text files"
  :dependencies ["https://github.com/andrewchambers/janet-uri"
                 "https://github.com/sepisoad/jurl"
                 "https://git.sr.ht/~bakpakin/temple"])

(declare-executable :name "jesty" :entry "jesty.janet")
