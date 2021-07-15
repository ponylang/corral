use "files"
use "ponytest"
use ".."
use "../../util"

class TestUpdateEmpty is UnitTest
  fun name(): String => "integration/update/empty-deps"
  fun apply(h: TestHelper) ? =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "update"
        "--verbose"
        "--bundle_dir"; Data(h, "empty-deps")?.path
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.contains("update:"))
        h.complete(ar.exit_code() == 0)
      })

class TestUpdateGithub is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/github-leaf"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "github-leaf")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "update"
        "--verbose"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("update:"))

          // Check that lock was at least created.
          let lock_file = data.dir_path("lock.json")?
          h.assert_true(lock_file.exists())

          let repos_dir = data.dir_path("_repos")?
          h.assert_true(repos_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

class TestUpdateScripts is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/scripts"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, [ "scripts"; "scripted" ])?

  fun tear_down(h: TestHelper val) =>
    data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(32_000_000_000)
    Execute(h,
      recover [ "update"; "--verbose"; "--bundle_dir"; data.dir() ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        ifdef windows then
        //@printf("h\n".cstring())
          h.assert_true(ar.stdout.contains("Success Windows!"))
        //@printf("\n".cstring())
          //if not ar.stdout.contains("Success Windows!") then
            //@printf("h\n".cstring())
            //@printf("stdout length: |%d|\n".cstring(), ar.stdout.size())
            //@printf("stdout: |%s|\n".cstring(), ar.std.cstring())
            //@printf("stdout length: |%d|\n".cstring(), ar.stdout.size())
          //end
        else
          h.assert_true(ar.stdout.contains("Success POSIX!"))
        end
        h.complete(ar.exit_code() == 0)
        //@printf("h\n".cstring())
      })


class TestUpdateBadGitReference is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/bad-git-reference"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "bad-git-reference")?

  fun tear_down(h: TestHelper val) =>
    data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(32_000_000_000)
    Execute(h,
      recover [ "update"; "--verbose"; "--bundle_dir"; data.dir() ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](128, ar.exit_code())

        h.complete(true)
      })
