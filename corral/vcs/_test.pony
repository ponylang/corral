use "ponytest"
//use "files"
//use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestGitSync)
    //test(_TestGitTagQuery)
    //test(_TestGitCheckout)

class iso _TestGitSync is UnitTest
  fun name(): String => "vcs/git/sync"

  fun apply(h: TestHelper) ? =>
    let vcs = VCSForType(h.env, "git")?
    let sync_op = vcs.sync_op({(repo: Repo) => None})

    //let ws = WorkSpec(dep.repo(), dep.version(), local, workspace)
    //ro.begin(ws)

  fun timed_out(h: TestHelper) =>
    h.complete(false)
