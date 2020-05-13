jesty
===========

REST client based on text files, simillar to one I was used to use in emacs.

#### Structure of the reqs:

- vars
  - bearer
  - url
- accounts
  - get
  - post
  - patch
- orders
  - get
  - ...

#### File content

```
0: # Patching on url <- comment means request spec start
1: PATCH @url <- url from variable
#   ^- http verb
2: Authorization: @bearer <- headers
   ^- name of the header
3: Content-Type: @json <- more headers
4: <- empty line means end of the header and start of the optional body
5: {
6:   "price": "bambilion" <- body of the req
7: }
8:
9: # Patching on url with id <- another request spec start



```

#### Usage:
`jesty accounts get 0`

#### Implementation

Simple CLI.
PEG for the file
