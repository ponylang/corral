use "files"
use "ponytest"
use ".."
use "../../util"

// Local non-VCS

class TestFetchEmpty is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/empty-deps"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "empty-deps")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    Execute(h,
      recover [
        "fetch"
        "--verbose"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.contains("fetch:"))
        h.complete(ar.exit_code() == 0)
      }
    )

class TestFetchLocalDirect is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/local-direct"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "local-direct")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })


class TestFetchMutuallyRecursive is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/mutually-recursive"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "mutually-recursive")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })


class TestFetchSelfReferential is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/self-referential"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "self-referential")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

class TestFetchScripts is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/scripts"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, [ "scripts"; "scripted" ])?

  fun tear_down(h: TestHelper val) =>
    data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [ "fetch"; "--bundle_dir"; data.dir() ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        ifdef windows then
          h.assert_true(ar.stdout.contains("Success Windows!"))
        else
          h.assert_true(ar.stdout.contains("Success POSIX!"))
        end
        h.complete(ar.exit_code() == 0)
      })

// Local VCS

class TestFetchLocalGits is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/local-git"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "local-git")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) ? =>
    h.long_test(10_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--bundle_dir"; Data(h, "local-git")?.path
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_true(repos_dir.join("bitbucket_org_cquinn_pony_thing_git")?.exists())
          h.assert_true(repos_dir.join("github_com_cquinn_pony_repo2_git")?.exists())
          h.assert_true(repos_dir.join("gitlab_com_cquinn1_justatest_git")?.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_cquinn_pony_repo2_bundle2b/bundle2b/corral.json")?.exists())
          h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

// Remote VCS

class TestFetchGithubDeep is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/github-deep"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "github-deep")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(5_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--verbose"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_true(repos_dir.join("github_com_ponylang_corral_test_repo_git")?.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle1/bundle1/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle2/bundle2/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle3/bundle3/corral.json")?.exists())

          h.complete(ar.exit_code() == 0)
        end
      })


class TestFetchRemoteGits is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/fetch/remote-gits"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "remote-gits")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(10_000_000_000)
    Execute(h,
      recover [
        "fetch"
        "--verbose"
        "--bundle_dir"; data.dir()
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("fetch:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_true(repos_dir.join("bitbucket_org_cquinn_pony_thing_git")?.exists())
          h.assert_true(repos_dir.join("github_com_ponylang_corral_test_repo_git")?.exists())
          h.assert_true(repos_dir.join("gitlab_com_cquinn1_justatest_git")?.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_true(corral_dir.join("bitbucket_org_cquinn_pony_thing/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle3/bundle3/corral.json")?.exists())
          h.assert_true(corral_dir.join("gitlab_com_cquinn1_justatest/corral.json")?.exists())

          h.complete(ar.exit_code() == 0)
        end
      })
