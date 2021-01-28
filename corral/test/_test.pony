use "ponytest"
use "files"
use integration = "integration"
use cmd = "../cmd"

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

    test(integration.TestFetchScripts)
    test(integration.TestUpdateScripts)

    cmd.Main.make().tests(test)

  fun @runtime_override_defaults(rto: RuntimeOptions) =>
    rto.ponynoblock = true
