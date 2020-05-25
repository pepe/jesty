(declare-project
  :name "jesty"
  :description "Janet REST client based on text files"
  :dependencies ["https://github.com/sepisoad/jurl"
                 "https://github.com/janet-lang/json"
                 "https://github.com/crocket/janet-utf8.git"])

(declare-executable :name "jesty" :entry "jesty.janet" :install true)
