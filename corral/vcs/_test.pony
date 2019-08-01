use "ponytest"
//use "files"
//use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestGitFetch)
    //test(_TestGitUpdate)
    //test(_TestGitTagQuery)

class iso _TestGitFetch is UnitTest
  fun name(): String =>
    "vcs/git/fetch"

  fun apply(h: TestHelper) ? =>
    let vcs = VcsForType(h.env, "git")?
    let fetch_op = vcs.fetch_op("master")?

    //let ws = WorkSpec(dep.repo(), dep.version(), local, workspace)
    //ro.begin(ws)

  fun timed_out(h: TestHelper) =>
    h.complete(false)
