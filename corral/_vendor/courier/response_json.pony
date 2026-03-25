use json = "json"

primitive ResponseJSON
  """
  Parse the body of an `HTTPResponse` as JSON.

  Returns the parsed `JsonValue` on success, or `JsonParseError` if the body
  is not valid JSON. This is deliberately minimal — users then use
  `JsonNav`, `JsonLens`, pattern matching, or whatever access pattern
  they prefer.

  ```pony
  use json = "json"

  match ResponseJSON(response)
  | let value: json.JsonValue =>
    // work with the parsed JSON
  | let err: json.JsonParseError =>
    env.out.print("Parse error: " + err.string())
  end
  ```
  """

  fun apply(response: HTTPResponse): (json.JsonValue | json.JsonParseError) =>
    """
    Parse `response.body` as JSON.

    Converts the body bytes to a `String` and parses with `JsonParser.parse()`.
    Returns `JsonParseError` if the body is empty or contains invalid JSON.
    """
    let body_str = String.from_array(response.body)
    json.JsonParser.parse(body_str)
