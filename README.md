jesty
===========

REST client for text specified requests.

## Generale

Jesty uses simple HTTP request specificatin, which is based on actual HTTP
protocol. It is very simillar to the one emacs http-client plugin uses.

## Request specification format

Just plain text file. I am using http extension so I can have filetype set
in my editor.

```
1: # definitions <- keyword for headers (for now) definitions shared by all the specifications in this file
2: Accept: application/json <- shared header
3: <- empty line means end of definitions
4: # Patching on url <- comment means request spec start, and
5: PATCH https://my.api/products <- http verb<space>url
6: Authorization: Bearer Avsdfasdfasdf <- optional header
7: Content-Type: application/json <- more headers
8: <- empty line means end of the header and start of the optional body
9: {
10:   "price": "bambilion" <- body of the req
11: }
12: <- every request must end with empty line
13: # Patching on url with id <- another request spec start
...
```

## Installation:

You need latest development version of Janet programming language installed.
Then you can install jesty with jpm package manager:

`[sudo] jpm install https://github.com/pepe/jesty`.

## Usage:

`jesty < input.http` will execute all the request specified in the input.http

`jesty < input.http` will execute all the request specified in the input.http

