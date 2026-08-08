interface ArtifactSource
  """
  Provides access to all available versions of a named
  artifact.
  """
  fun ref all_versions_of(name: String): Iterator[Artifact]
    """
    Return an iterator over all versions of the named
    artifact.
    """
