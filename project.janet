(declare-project
  :name "jesty"
  :description "Janet REST client based on text files"
  :dependencies ["https://github.com/sepisoad/jurl"])

(declare-executable :name "jesty" :entry "jesty.janet" :install true)
