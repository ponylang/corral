"""
# JSON Package

The `json` package provides the
[JSONDoc](json-JSONDoc.md) class both as a container
for a JSON document and as means of parsing from and
writing to [String](builtin-String.md).

## JSON Representation

JSON is represented in Pony as the following types:

* object - [JSONObject](json-JSONObject.md)
* array  - [JSONArray](json-JSONArray.md)
* string - [String](builtin-String.md)
* integer - [I64](builtin-I64.md)
* float   - [F64](builtin-F64.md)
* boolean - [Bool](builtin-Bool.md)
* null    - [None](builtin-None.md)

The collection types JSONObject and JSONArray can contain
any other JSON structures arbitrarily nested.

[JSONType](json-JSONType.md) is used to subsume all
possible JSON types. It can also be used to describe
everything that can be serialized using this package.

## Parsing JSON

For getting JSON from a String into proper Pony data
structures,
[JSONDoc.parse](json-JSONDoc.md#parse) needs to be used.
This will populate the public field `JSONDoc.data`, which
is [None](builtin-None.md), if
[parse](json-JSONDoc.md#parse) has not been called yet.

Every call to [parse](json-JSONDoc.md#parse) overwrites
the `data` field, so one JSONDoc instance can be used to
parse multiple JSON Strings one by one.

```pony
let doc = JSONDoc
// parsing
doc.parse(
  "{\"key\":\"value\", \"property\": true,"
    + " \"array\":[1, 2.5, false]}")?

// extracting values from a JSON structure
let json: JSONObject = doc.data as JSONObject
let key: String = json.data("key")? as String
let property: Bool =
  json.data("property")? as Bool
let array: JSONArray =
  json.data("array")? as JSONArray
let first: I64 = array.data(0)? as I64
let second: F64 = array.data(1)? as F64
let last: Bool = array.data(2)? as Bool
```

### Sending JSON

[JSONDoc](json-JSONDoc.md) has the `ref` reference
capability, which means it is not sendable by default. If
you need to send it to another actor you need to recover
it to a sendable reference capability (either `val` or
`iso`). For the sake of simplicity it is recommended to do
the parsing already in the recover block:

```pony
// sending an iso doc
let json_string = "{\"array\":[1, true, null]}"
let sendable_doc: JSONDoc iso =
  recover iso JSONDoc.>parse(json_string)? end
some_actor.send(consume sendable_doc)

// sending a val doc
let val_doc: JSONDoc val =
  recover val JSONDoc.>parse(json_string)? end
some_actor.send_val(val_doc)
```

When sending an `iso` JSONDoc it is important to recover
it to a `ref` on the receiving side in order to be able
to properly access the json structures in `data`.

## Writing JSON

JSON is written using the
[JSONDoc.string](json-JSONDoc.md#string) method. This
will serialize the contents of the `data` field to
[String](builtin-String.md).

```pony
// building up the JSON data structure
let doc = JSONDoc
let obj = JSONObject
obj.data("key") = "value"
obj.data("property") = true
obj.data("array") =
  JSONArray.from_array(
    [as JSONType: I64(1); F64(2.5); false])
doc.data = obj

// writing to String
env.out.print(
  doc.string(
    where indent = "  ", pretty_print = true)
)

```
"""
