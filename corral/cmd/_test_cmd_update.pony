use "files"
use "ponytest"
use "../bundle"
use "../util"
use "../vcs"

actor _TestCmdUpdate is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestEmptyDeps)
    test(_TestMutuallyRecursive)
    test(_TestRegression120)
    test(_TestSelfReferential)

class iso _TestEmptyDeps is UnitTest
  """
  Verify that when using an corral.json for with empty deps, that there
  are never any sync, tag query, or checkout operations executed.
  """

  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderTestRunner(
      h,
      "empty-deps",
      _OpsRecorder(h, 0, 0, 0))?

class iso _TestMutuallyRecursive is UnitTest
  """
  Verify that when using mutually recursive corral.json files that we
  execute the correct number of operations
  """

  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderTestRunner(
      h,
      "mutually-recursive/foo",
      _OpsRecorder(h, 2, 2, 2))?

class iso _TestRegression120 is UnitTest
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
    _OpsRecorderTestRunner(
      h,
      "regression-120/bundle-entrypoint",
      _OpsRecorder(h, 4, 4, 4))?

class iso _TestSelfReferential is UnitTest
  """
  Verify that a self reference in a corral.json results in only 1 operation
  """
  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    _OpsRecorderTestRunner(
      h,
      "self-referential",
      _OpsRecorder(h, 1, 1, 1))?

primitive _OpsRecorderTestRunner
  fun apply(h: TestHelper, dep_path: String val, recorder: _OpsRecorder) ? =>
    """
    Runs an _OpsRecorder test.
    """
    let auth = h.env.root as AmbientAuth
    let log = Log(LvlNone, h.env.err, SimpleLogFormatter)
    let fp: FilePath = _TestData.file_path_from(h, dep_path)?
    let repo_cache = _TestRepoCache(auth)?
    let ctx = Context(h.env, log, log, false, repo_cache)
    let project = Project(auth, log, fp)
    let bundle = Bundle.load(fp, log)?
    let vcs_builder: VCSBuilder = _TestCmdUpdateVCSBuilder(recorder)

    let updater = _Updater(ctx, project, consume bundle, vcs_builder, recorder)

    // when updater is finished, it will send a `cmd_completed` message to
    // _OpsRecorder which will trigger pass/fail
    h.long_test(2_000_000_000)

actor _OpsRecorder is CmdResultReceiver
  let _h: TestHelper

  let _expected_sync: U64
  let _expected_tag_query: U64
  let _expected_checkout: U64

  var _sync: U64 = 0
  var _tag_query: U64 = 0
  var _checkout: U64 = 0

  new create(h: TestHelper, s: U64, tq: U64, c: U64) =>
    _h = h
    _expected_sync = s
    _expected_tag_query = tq
    _expected_checkout = c

  be sync() =>
    _sync = _sync + 1

  be tag_query() =>
    _tag_query = _tag_query + 1

  be checkout() =>
    _checkout = _checkout + 1

  be cmd_completed() =>
    _h.assert_eq[U64](_expected_sync, _sync)
    _h.assert_eq[U64](_expected_tag_query, _tag_query)
    _h.assert_eq[U64](_expected_checkout, _checkout)

    _h.complete(true)


class val _TestCmdUpdateVCSBuilder is VCSBuilder
  let _recorder: _OpsRecorder

  new val create(recorder: _OpsRecorder) =>
    _recorder = recorder

  fun val apply(kind: String): VCS =>
    _RecordedVCS(_recorder)


class val _RecordedVCS is VCS
  let _recorder: _OpsRecorder

  new val create(recorder: _OpsRecorder) =>
    _recorder = recorder

  fun val sync_op(resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation =>
    _RecordedSync(_recorder, next)

  fun val tag_query_op(resultReceiver: RepoOperationResultReceiver, receiver: TagListReceiver): RepoOperation =>
    _RecordedTagQuery(_recorder, receiver)

  fun val checkout_op(rev: String, resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation =>
    _RecordedCheckout(_recorder, next)


class val _RecordedSync is RepoOperation
  let _recorder: _OpsRecorder
  let _next: RepoOperation

  new val create(recorder: _OpsRecorder, next: RepoOperation) =>
    _recorder = recorder
    _next = next

  fun val apply(repo: Repo) =>
    _recorder.sync()
    _next(repo)


class val _RecordedTagQuery is RepoOperation
  let _recorder: _OpsRecorder
  let _next: TagListReceiver

  new val create(recorder: _OpsRecorder, next: TagListReceiver) =>
    _recorder = recorder
    _next = next

  fun val apply(repo: Repo) =>
    let tags: Array[String] iso = recover Array[String] end
    _recorder.tag_query()
    _next(repo, consume tags)


class val _RecordedCheckout is RepoOperation
  let _recorder: _OpsRecorder
  let _next: RepoOperation

  new val create(recorder: _OpsRecorder, next: RepoOperation) =>
    _recorder = recorder
    _next = next

  fun val apply(repo: Repo) =>
    _recorder.checkout()
    _next(repo)

primitive _TestData
  fun file_path_from(h: TestHelper, subdir: String = ""): FilePath ? =>
    let auth = h.env.root as AmbientAuth
    FilePath(auth, "corral/test/testdata")?.join(subdir)?

primitive _TestRepoCache
  fun apply(auth: AmbientAuth): FilePath ? =>
    FilePath(auth,"_test_cmd_update_repo_cache")?
