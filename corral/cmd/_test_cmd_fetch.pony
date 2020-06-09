use "files"
use "ponytest"
use "../bundle"
use "../util"
use "../vcs"

actor _TestCmdFetch is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestFetchEmptyDeps)
    test(_TestFetchEmptyFile)
    test(_TestFetchMutuallyRecursive)
    test(_TestFetchSelfReferential)

class iso _TestFetchEmptyDeps is UnitTest
  """
  Verify that when using corral.json with empty deps, that there
  are never any sync, tag query, or checkout operations executed.
  """

  fun name(): String =>
    "cmd/fetch/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderFetchTestRunner(
      h,
      "empty-deps",
      _OpsRecorder(h, 0, 0, 0))?

class iso _TestFetchEmptyFile is UnitTest
  """
  Verify that when using corral.json with an empty deps file, that there
  are never any sync, tag query, or checkout operations executed.
  """

  fun name(): String =>
    "cmd/fetch/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderFetchTestRunner(
      h,
      "empty-file",
      _OpsRecorder(h, 0, 0, 0))?

class iso _TestFetchSelfReferential is UnitTest
  """
  Verify that a self reference in a corral.json results in only 1 operation
  """
  fun name(): String =>
    "cmd/fetch/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderFetchTestRunner(
      h,
      "self-referential",
      _OpsRecorder(h, 1, 0, 1))?

class iso _TestFetchMutuallyRecursive is UnitTest
  """
  Verify that when using mutually recursive corral.json files that we
  execute the correct number of operations
  """

  fun name(): String =>
    "cmd/fetch/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderFetchTestRunner(
      h,
      "mutually-recursive/foo",
      _OpsRecorder(h, 2, 0, 2))?

primitive _OpsRecorderFetchTestRunner
  fun apply(h: TestHelper, dep_path: String val, recorder: _OpsRecorder) ? =>
    """
    Runs an _OpsRecorder test.
    """
    let auth = h.env.root as AmbientAuth
    let log = Log(LvlNone, h.env.err, SimpleLogFormatter)
    let fp: FilePath = _TestData.file_path_from(h, dep_path)?
    let repo_cache = _TestRepoCache(auth, "_test_cmd_fetch_repo_cache")?
    let ctx = Context(h.env, log, log, false, repo_cache)
    let project = Project(auth, log, fp)
    let bundle = Bundle.load(fp, log)?
    let vcs_builder: VCSBuilder = _TestCmdFetchVCSBuilder(recorder)

    let fetcher = _Fetcher(ctx, project, consume bundle, vcs_builder, 
      recorder)

    // when fetcher is finished, it will send a `cmd_completed` message to
    // _OpsRecorder which will trigger pass/fail

class val _TestCmdFetchVCSBuilder is VCSBuilder
  let _recorder: _OpsRecorder

  new val create(recorder: _OpsRecorder) =>
    _recorder = recorder

  fun val apply(kind: String): VCS =>
    _RecordedVCS(_recorder)
