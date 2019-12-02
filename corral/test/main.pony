use "ponytest"
use "files"
use integration = "integration"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
    env.err.print("Test Main CWD is: " + Path.cwd())

  fun tag tests(test: PonyTest) =>
    test(TestGitParseTags)
    test(TestBundle)

    test(integration.TestHelp)
    test(integration.TestVersion)
    test(integration.TestInfo)
    test(integration.TestInfoWithoutBundle)
    test(integration.TestUpdateEmpty)
    test(integration.TestUpdateGithub)
    test(integration.TestFetchEmpty)
    test(integration.TestFetchGithubDeep)
    test(integration.TestFetchRemoteGits)
    test(integration.TestRun)
    test(integration.TestRunWithoutBundle)
    test(integration.TestClean)

class TestDir
  let path: String = "corral/test/testdata"
  fun apply(auth: AmbientAuth, subpath: String): FilePath ? =>
    FilePath(auth, path)?.join(subpath)?
