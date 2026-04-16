use json = "json"

primitive DecodeJSON[A: Any val]
  """
  Parse and decode an HTTP response body as a typed domain object in one step.

  Combines `ResponseJSON` (JSON parsing) with a `JSONDecoder` (structural
  decoding) into a single call. The three-way return type distinguishes
  between success, parse failure, and decode failure:

  - `A` — the response body was valid JSON and matched the decoder's expected
    structure
  - `JsonParseError` — the response body was not valid JSON syntax
  - `JSONDecodeError` — the JSON was valid but didn't match the decoder's
    expected structure (missing fields, wrong types, etc.)

  ```pony
  use "courier"
  use json = "json"

  // In on_response_complete():
  match DecodeJSON[User](response, UserDecoder)
  | let user: User =>
    env.out.print("Hello, " + user.name)
  | let err: json.JsonParseError =>
    env.out.print("Invalid JSON: " + err.string())
  | let err: JSONDecodeError =>
    env.out.print("Unexpected structure: " + err.string())
  end
  ```
  """

  fun apply(
    response: HTTPResponse,
    decoder: JSONDecoder[A])
    : (A | json.JsonParseError | JSONDecodeError)
  =>
    """
    Parse `response.body` as JSON, then decode with `decoder`.

    Returns `JsonParseError` if the body isn't valid JSON, `JSONDecodeError` if
    the JSON doesn't match the decoder's expected structure, or the decoded
    value on success.
    """
    match \exhaustive\ ResponseJSON(response)
    | let value: json.JsonValue => decoder(value)
    | let err: json.JsonParseError => err
    end
