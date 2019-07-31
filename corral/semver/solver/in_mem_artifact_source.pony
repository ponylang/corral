use "collections"
use "../utils"

class InMemArtifactSource is ArtifactSource
  let artifact_sets_by_name: Map[String, Set[Artifact]] = Map[String, Set[Artifact]]

  // see: https://irclog.whitequark.org/ponylang/2016-12-11#18388988
  new create() =>
    None

  fun ref add(a: Artifact) =>
    try
      artifact_sets_by_name(a.name)?.set(a)
    else
      artifact_sets_by_name(a.name) = Set[Artifact].>set(a)
    end

  fun ref all_versions_of(name: String): Iterator[Artifact] =>
    try
      artifact_sets_by_name(name)?.values()
    else
      EmptyIterator[Artifact]
    end
