use "files"
use "ponytest"
use ".."
use "../../util"

class TestRun is UnitTest
  fun name(): String => "integration/run"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "run"
      "--bundle_dir"; Path.join(TestDir.path, "empty-deps")
      "--"
      "ponyc"; "-version"
    ] end, CheckRun)

class CheckRun is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.contains("compiled with: "))
    h.complete(ar.exit_code == 0)

class TestRunWithoutBundle is UnitTest
  fun name(): String => "integration/run/without-bundle"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "run"
      "--bundle_dir"; "/"
      "--"
      "ponyc"; "-version"
    ] end, CheckRunWithoutBundle)

class CheckRunWithoutBundle is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.contains("compiled with: "))
    h.complete(ar.exit_code == 0)
