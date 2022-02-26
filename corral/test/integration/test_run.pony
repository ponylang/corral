use "files"
use "pony_test"
use ".."
use "../../util"

class \nodoc\ TestRun is UnitTest
  fun name(): String => "integration/run"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; Data(h, "empty-deps")?.path
        "--"
        "ponyc"; "-version"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains("compiled with: "))
        h.complete(ar.exit_code() == 0)
      })

class \nodoc\ TestRunWithoutBundle is UnitTest
  fun name(): String => "integration/run/without-bundle"
  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; "/"
        "--"
        "ponyc"; "-version"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains("compiled with: "))
        h.complete(ar.exit_code() == 0)
      })

class \nodoc\ TestRunNoArgs is UnitTest
  fun name(): String => "integration/run/no-args"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; Data(h, "empty-deps")?.path
        "--"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](1, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains("no run command provided"))
        h.complete(ar.exit_code() == 1)
      })

class \nodoc\ TestRunBinaryNotFound is UnitTest
  fun name(): String => "integration/run/binary-not-found"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; Data(h, "empty-deps")?.path
        "--"
        "grmpf_i_do_not_exist_anywhere_and_i_am_not_absolute"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](1, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains("unable to find binary \"grmpf_i_do_not_exist_anywhere_and_i_am_not_absolute\""))
        h.complete(ar.exit_code() == 1)
      })

class \nodoc\ TestRunBinaryNotFoundAbsolute is UnitTest
  fun name(): String => "integration/run/binary-not-found-absolute"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
    let path = Path.join("/path/to", "grmpf_i_do_not_exist_anywhere")
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; Data(h, "empty-deps")?.path
        "--"
        path
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_ne[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains(path + " does not exist or is a directory"))
        h.complete(ar.exit_code() != 0)
      })

class \nodoc\ TestRunBinaryInParentFolder is UnitTest
  fun name(): String => "integration/run/binary-in-parent-folder"
  fun apply(h: TestHelper) ? =>
    let cwd = Path.cwd()
    let ponyc_path = try
      RelativePathToPonyc(h)?
    else
      h.log("Unable to determine relative path to ponyc, skipping.")
      return
    end
    h.log(ponyc_path)
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "run"
        "--bundle_dir"; Data(h, "empty-deps")?.path
        "--"
        "ponyc"; "-version"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.lower().contains("compiled with: "))
        h.complete(ar.exit_code() == 0)
      })
