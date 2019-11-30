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


class TestFetchGithubDeep is UnitTest
  fun name(): String => "integration/fetch-github-deep"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "github-deep")
    ] end, CheckFetchGithubDeep)

primitive CheckFetchGithubDeep is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let repos_dir = TestDir(auth, "github-deep/_repos")?
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo1_git")?.exists())
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo2_git")?.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "github-deep/_corral")?
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo1_bundle1/bundle1/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2a/bundle2a/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end


class TestFetchRemoteGits is UnitTest
  fun name(): String => "integration/fetch-remote-gits"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "remote-gits")
    ] end, CheckFetchRemoteGits)

primitive CheckFetchRemoteGits is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let repos_dir = TestDir(auth, "remote-gits/_repos")?
      h.assert_true(repos_dir.join("bitbucket_org_cquinn_pony_thing_git")?.exists())
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo2_git")?.exists())
      h.assert_true(repos_dir.join("gitlab_com_cquinn1_justatest_git")?.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "remote-gits/_corral")?
      h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
      h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end


class TestFetchLocalDirect is UnitTest
  fun name(): String => "integration/fetch-local-direct"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "local-direct")
    ] end, CheckFetchLocalDirect)

primitive CheckFetchLocalDirect is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let corral_dir = TestDir(auth, "local-direct/_corral")?
      h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
      h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end
