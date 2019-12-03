use "files"
use "ponytest"
use ".."
use "../../util"

// Local non-VCS

class TestFetchEmpty is UnitTest
  fun name(): String => "integration/fetch/empty-deps"
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


class TestFetchLocalDirect is UnitTest
  fun name(): String => "integration/fetch/local-direct"
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

      let repos_dir = TestDir(auth, "local-direct/_repos")?
      h.assert_false(repos_dir.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "local-direct/_corral")?
      h.assert_false(corral_dir.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end


class TestFetchMutuallyRecursive is UnitTest
  fun name(): String => "integration/fetch/mutually-recursive"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "mutually-recursive")
    ] end, CheckFetchMutuallyRecursive)

primitive CheckFetchMutuallyRecursive is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let repos_dir = TestDir(auth, "mutually-recursive/_repos")?
      h.assert_false(repos_dir.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "mutually-recursive/_corral")?
      h.assert_false(corral_dir.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end


class TestFetchSelfReferential is UnitTest
  fun name(): String => "integration/fetch/self-referential"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "self-referential")
    ] end, CheckFetchSelfReferential)

primitive CheckFetchSelfReferential is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let repos_dir = TestDir(auth, "self-referential/_repos")?
      h.assert_false(repos_dir.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "self-referential/_corral")?
      h.assert_false(corral_dir.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end

// Local VCS

class TestFetchLocalGits is UnitTest
  fun name(): String => "integration/fetch/local-git"
  fun apply(h: TestHelper) =>
    h.long_test(10_000_000_000)
    Execute(h, recover [
      "fetch"
      "--bundle_dir"; Path.join(TestDir.path, "local-git")
    ] end, CheckFetchLocalGits)

primitive CheckFetchLocalGits is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    try
      h.assert_eq[I32](0, ar.exit_code)
      h.assert_true(ar.stdout.contains("fetch:"))

      let auth = h.env.root as AmbientAuth

      let repos_dir = TestDir(auth, "local-gits/_repos")?
      h.assert_true(repos_dir.join("bitbucket_org_cquinn_pony_thing_git")?.exists())
      h.assert_true(repos_dir.join("github_com_cquinn_pony_repo2_git")?.exists())
      h.assert_true(repos_dir.join("gitlab_com_cquinn1_justatest_git")?.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "local-gits/_corral")?
      h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
      h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end

// Remote VCS

class TestFetchGithubDeep is UnitTest
  fun name(): String => "integration/fetch/github-deep"
  fun apply(h: TestHelper) =>
    h.long_test(5_000_000_000)
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
      h.assert_true(repos_dir.join("github_com_ponylang_corral_test_repo_git")?.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "github-deep/_corral")?
      h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle1/bundle1/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle2/bundle2/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle3/bundle3/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end


class TestFetchRemoteGits is UnitTest
  fun name(): String => "integration/fetch/remote-gits"
  fun apply(h: TestHelper) =>
    h.long_test(10_000_000_000)
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
      h.assert_true(repos_dir.join("github_com_ponylang_corral_test_repo_git")?.exists())
      h.assert_true(repos_dir.join("gitlab_com_cquinn1_justatest_git")?.exists())
      repos_dir.remove()

      let corral_dir = TestDir(auth, "remote-gits/_corral")?
      h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
      h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle3/bundle3/corral.json")?.exists())
      h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())
      corral_dir.remove()

      h.complete(ar.exit_code == 0)
    end
