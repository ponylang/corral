use "files"
use "ponytest"
use "../vcs"

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
  fun apply(auth: AmbientAuth, path: String): FilePath ? =>
    FilePath(auth, path)?