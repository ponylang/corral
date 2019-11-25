use "files"
use "ponytest"
use ".."
use "../../util"

class TestFetchEmpty is UnitTest
  fun name(): String => "integration/fetch-empty-deps"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "empty-deps")
    ] end, CheckFetchEmpty)

primitive CheckFetchEmpty is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.contains("fetch:"))
    h.complete(ar.exit_code == 0)
    //h.env.out.print(ar.stdout)

class TestFetchGithub is UnitTest
  fun name(): String => "integration/fetch-github-real"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "github-real")
    ] end, CheckFetchGithub)

primitive CheckFetchGithub is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth
      let corral_dir = TestDir(auth, "github-real/_corral")?
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo1_bundle1/bundle1/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2a/bundle2a/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
      corral_dir.remove()

      let repos_dir = TestDir(auth, "github-real/_repos")?
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo1_git")?.exists())
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo2_git")?.exists())
      repos_dir.remove()

      h.complete(ar.exit_code == 0)
      //h.env.out.print(ar.stdout)
      //h.env.err.print(ar.stderr)
    end
