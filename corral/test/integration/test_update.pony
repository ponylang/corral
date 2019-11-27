use "files"
use "ponytest"
use ".."
use "../../util"

class TestUpdateEmpty is UnitTest
  fun name(): String => "integration/update-empty-deps"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "update"
      "--bundle_dir"; Path.join(TestDir.path, "empty-deps")
    ] end, CheckUpdateEmpty)

class CheckUpdateEmpty is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.contains("update:"))
    h.complete(ar.exit_code == 0)

class TestUpdateGithub is UnitTest
  fun name(): String => "integration/update-github-leaf"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "update"
      "--bundle_dir"; Path.join(TestDir.path, "github-leaf")
    ] end, CheckUpdateGithub)

class CheckUpdateGithub is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("update:"))

      // Check that lock was at least created.
      let auth = h.env.root as AmbientAuth
      let lock_file = TestDir(auth, "github-leaf/lock.json")?
      h.assert_true(lock_file.exists())
      lock_file.remove()
      let repos_dir = TestDir(auth, "github-leaf/_repos")?
      h.assert_true(repos_dir.exists())
      repos_dir.remove()

      h.complete(ar.exit_code == 0)
    end
