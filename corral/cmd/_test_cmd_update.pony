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

class iso _TestEmptyDeps is UnitTest
  fun name(): String =>
    "cmd/update/" + __loc.type_name()

  fun apply(h: TestHelper) ? =>
    """
    Verify that when using an corral.json for with empty deps, that there
    are never any sync, tag query, or checkout operations executed.
    """
    let auth = h.env.root as AmbientAuth
    let log = Log(LvlNone, h.env.err, SimpleLogFormatter)
    let fp: FilePath = _TestData.file_path_from(h, "empty-deps")?
    let repo_cache = _TestRepoCache(auth)?
    let ctx = Context(h.env, log, log, false, repo_cache)
    let project = Project(auth, log, fp)
    let bundle = Bundle.load(fp, log)?
    let recorder = _OpsRecorder(h, 0, 0, 0)
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

  fun val sync_op(next: RepoOperation): RepoOperation =>
    _RecordedSync(_recorder, next)

  fun val tag_query_op(receiver: TagListReceiver): RepoOperation =>
    _RecordedTagQuery(_recorder, receiver)

  fun val checkout_op(rev: String, next: RepoOperation): RepoOperation =>
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
