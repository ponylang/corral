use "files"
use "ponytest"
use "../bundle"
use "../util"
use "../vcs"

actor _TestCmdUpdate is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestUpdateEmptyDeps)
    test(_TestUpdateMutuallyRecursive)
    test(_TestUpdateRegression120)
    test(_TestUpdateSelfReferential)

class iso _TestUpdateEmptyDeps is UnitTest
  """
  Verify that when using an corral.json for with empty deps, that there
  are never any sync, tag query, or checkout operations executed.
  """

  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderUpdateTestRunner(
      h,
      "empty-deps",
      _OpsRecorder(h, 0, 0, 0))?

class iso _TestUpdateMutuallyRecursive is UnitTest
  """
  Verify that when using mutually recursive corral.json files that we
  execute the correct number of operations
  """

  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderUpdateTestRunner(
      h,
      "mutually-recursive/foo",
      _OpsRecorder(h, 2, 2, 2))?

class iso _TestUpdateRegression120 is UnitTest
  """
  Issue #120 identified a problem with transitive dependencies that resulted
  in too many operations being performaned across the loading of all
  dependencies.

  The test as currently constituted, consists of a bundles with 2
  dependencies. One of those has 2 more in a transitive fashion, that should
  result in 4 syncs and corresponding actions happening. However, due to a
  bug in _Updater, it currently does 11.

  With a real VCS like Git, the number that results from it is variable
  based on timing. This test exists to prove that issue #120 is fixed and
  to prevent a similar bug from being introduced in the future.
  """
  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderUpdateTestRunner(
      h,
      "regression-120/bundle-entrypoint",
      _OpsRecorder(h, 4, 4, 4))?

class iso _TestUpdateSelfReferential is UnitTest
  """
  Verify that a self reference in a corral.json results in only 1 operation
  """
  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderUpdateTestRunner(
      h,
      "self-referential",
      _OpsRecorder(h, 1, 1, 1))?

primitive _OpsRecorderUpdateTestRunner
  fun apply(h: TestHelper, dep_path: String val, recorder: _OpsRecorder) ? =>
    """
    Runs an _OpsRecorder test.
    """
    let auth = h.env.root as AmbientAuth
    let log = Log(LvlNone, h.env.err, SimpleLogFormatter)
    let fp: FilePath = _TestData.file_path_from(h, dep_path)?
    let repo_cache = _TestRepoCache(auth, "_test_cmd_update_repo_cache")?
    let ctx = Context(h.env, log, log, false, repo_cache)
    let project = Project(auth, log, fp)
    let bundle = Bundle.load(fp, log)?
    let vcs_builder: VCSBuilder = _TestCmdUpdateVCSBuilder(recorder)

    let updater = _Updater(ctx, project, consume bundle, vcs_builder, recorder)

    // when updater is finished, it will send a `cmd_completed` message to
    // _OpsRecorder which will trigger pass/fail
    h.long_test(2_000_000_000)

class val _TestCmdUpdateVCSBuilder is VCSBuilder
  let _recorder: _OpsRecorder

  new val create(recorder: _OpsRecorder) =>
    _recorder = recorder

  fun val apply(kind: String): VCS =>
    _RecordedVCS(_recorder)
