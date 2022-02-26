use "files"
use "../logger"
use "pony_test"
use "../bundle"
use "../util"

class  \nodoc\ TestBundle is UnitTest
  fun name(): String => "bundle/bundle"

  fun apply(h: TestHelper) ? =>
    let log = StringLogger(Error, h.env.err, SimpleLogFormatter)

    h.assert_error(_BundleLoad(Data(h, "notfound!")?, log), "nonexistant directory")
    h.assert_error(_BundleLoad(Data(h, "empty-dir")?, log), "no bundle.json")
    h.assert_error(_BundleLoad(Data(h, "bad-json")?, log), "bad corral.json")

    h.assert_no_error(_BundleLoad(Data(h, "empty-file")?, log), "empty corral.json")
    h.assert_no_error(_BundleLoad(Data(h, "empty-deps")?, log), "empty deps")
    h.assert_no_error(_BundleLoad(Data(h, "github-leaf")?, log), "github dep")
    h.assert_no_error(_BundleLoad(Data(h, "local-git")?, log), "local-git dep")
    h.assert_no_error(_BundleLoad(Data(h, "local-direct")?, log), "local-direct dep")
    h.assert_no_error(_BundleLoad(Data(h, "abitofeverything")?, log), "mixed deps")

    // TODO: figure out useful tests for Bundle creation
    //h.assert_error(_BundleCreate("notfound"))?, log), "create in nonexistant directory")
    //h.assert_no_error(_BundleCreate(DataDir("empty")?, log), "create in directory with no bunde.json")

class  \nodoc\ _BundleLoad is ITest
  let path: FilePath
  let log: Logger[String]

  new create(path': FilePath, log': Logger[String]) =>
    path = path'
    log = log'

  fun apply() ? => Bundle.load(path, log)?

class  \nodoc\ _BundleCreate is ITest
  let path: FilePath
  let log: Logger[String]

  new create(path': FilePath, log': Logger[String]) =>
    path = path'
    log = log'

  fun apply() => Bundle.create(path, log)
