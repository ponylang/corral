interface ArtifactSource
  fun ref all_versions_of(name: String): Iterator[Artifact]
