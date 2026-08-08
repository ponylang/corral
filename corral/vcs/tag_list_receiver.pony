interface val TagListReceiver
  """
  Receives a list of tags from a tag query operation.
  """

  fun apply(repo: Repo, tags: Array[String] val)
  """
  Handle the received list of tags.
  """

class TagQueryPrinter is TagListReceiver
  """
  Prints tag query results to an output stream.
  """

  let out: OutStream

  new create(out': OutStream) => out = out'

  fun apply(repo: Repo, tags: Array[String] val) =>
    for tg in tags.values() do
      out.print("tag: " + tg)
    end
