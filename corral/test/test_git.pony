use "ponytest"
use "../vcs"
use "../util"

actor _GitParseTagsResultReceiver is RepoOperationResultReceiver
  be reportError(repo: Repo, actionResult: ActionResult) => None

class TestGitParseTags is UnitTest
  fun name(): String => "git/parse-tags"

  fun apply(h: TestHelper) ? =>
    let stdout: String =
      """
      b0b68f7a394ca6cd13198f2fdf7240bf7a116d8e refs/heads/master
      329dda3c3db8f75c1186da9cf4fb05da183c389b refs/heads/2852-changelog
      329dda3c3db8f75c1186da9cf4fb05da183c389b refs/remotes/origin/2852-changelog
      b0b68f7a394ca6cd13198f2fdf7240bf7a116d8e refs/remotes/origin/HEAD
      45a1d66ee94108f58ce5525e411c716871fcb37f refs/remotes/origin/MinGW64
      cefc960800ba619e2a750fe49da06eb7408dc07b refs/remotes/origin/bionic-source-instructions
      4d7087e672a3c056bbe2e01a54df3dcaa1b1bba5 refs/tags/0.1.0
      652c628ed96dbdcdc36622c9b6e01981b0a066a7 refs/tags/0.1.1
      4e26ed4fd55ce7f02a589d5dda4128e3c5003d55 refs/tags/0.1.2
      d3f64c921b6d6355427caa46820f712cd4911928 refs/tags/0.1.3
      41051c06abb768ecc041421adbbc192e76961c7c refs/tags/0.1.4
      cb82ac111edb1a32d42fc8cf8fccbc77908a752a refs/tags/0.1.5
      dcf27b504214ad30198c828ae4db2512862bed78 refs/tags/0.1.6
      90989eb597967edc5ac6fca97c1b68cc2fc6b471 refs/tags/0.1.7
      """
    let expect: Array[String] =
      ["0.1.0"; "0.1.1"; "0.1.2"; "0.1.3"; "0.1.4"; "0.1.5"; "0.1.6"; "0.1.7"]

    let git = GitVCS(h.env)?
    let rcv = {(repo: Repo, tags: Array[String] val) => None}
    let res = GitQueryTags(git, _GitParseTagsResultReceiver.create(), consume rcv).parse_tags(stdout)
    for pair in expect.pairs() do
      (let i: USize, let expected: String) = pair
      h.assert_eq[String](expected, res(i)?)
    end
