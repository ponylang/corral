use "files"
use "ponytest"
use ".."
use "../../util"

class  \nodoc\ TestUpdateEmpty is UnitTest
  fun name(): String => "integration/update/empty-deps"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
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

class  \nodoc\ TestUpdateLocalDirect is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/local-direct"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, ["local-direct"; "empty-deps"])?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
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

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

class  \nodoc\ TestUpdateMutuallyRecursive is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/mutually-recursive"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "mutually-recursive")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)

    Execute(h,
      recover [
        "update"
        "--verbose"
        "--bundle_dir"; Path.join(data.dir(), "foo")
      ] end,
      {(h: TestHelper, ar: ActionResult)(data=data) =>
        try
          h.assert_eq[I32](0, ar.exit_code())
          h.assert_true(ar.stdout.contains("update:"))

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

class  \nodoc\ TestUpdateSelfReferential is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/self-referential"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "self-referential")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
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

          let repos_dir = data.dir_path("_repos")?
          h.assert_false(repos_dir.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_false(corral_dir.exists())

          h.complete(ar.exit_code() == 0)
        end
      })

class  \nodoc\ TestUpdateGithub is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/github-leaf"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "github-leaf")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
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

class  \nodoc\ TestUpdateScripts is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/scripts"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, [ "scripts"; "scripted" ])?

  fun tear_down(h: TestHelper val) =>
    data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [ "update"; "--verbose"; "--bundle_dir"; data.dir() ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        ifdef windows then
          h.assert_true(ar.stdout.contains("Success Windows!"))
        else
          h.assert_true(ar.stdout.contains("Success POSIX!"))
        end
        h.complete(ar.exit_code() == 0)
      })

class  \nodoc\ TestUpdateGithubDeep is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/github-deep"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "github-deep")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
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

          let repos_dir = data.dir_path("_repos")?
          h.assert_true(repos_dir.join("github_com_ponylang_corral_test_repo_git")?.exists())

          let corral_dir = data.dir_path("_corral")?
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle1/bundle1/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle2/bundle2/corral.json")?.exists())
          h.assert_true(corral_dir.join("github_com_ponylang_corral_test_repo_bundle3/bundle3/corral.json")?.exists())

          h.complete(ar.exit_code() == 0)
        end
      })


class  \nodoc\ TestUpdateRemoteGits is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/remote-gits"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "remote-gits")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
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

class  \nodoc\ TestUpdateBadGitReference is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/update/bad-git-reference"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "bad-git-reference")?

  fun tear_down(h: TestHelper val) =>
    data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [ "update"; "--verbose"; "--bundle_dir"; data.dir() ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](128, ar.exit_code())

        h.complete(true)
      })
