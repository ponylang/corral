use "pony_test"
use "files"
use integration = "integration"
use cmd = "../cmd"

actor \nodoc\ Main is TestList
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
    test(integration.TestUpdateBadGitReference)
    test(integration.TestUpdateGithubDeep)
    test(integration.TestUpdateRemoteGits)
    test(integration.TestUpdateLocalDirect)
    test(integration.TestUpdateMutuallyRecursive)
    test(integration.TestUpdateSelfReferential)
    test(integration.TestRun)
    test(integration.TestRunWithoutBundle)
    test(integration.TestRunNoArgs)
    test(integration.TestRunBinaryNotFound)
    test(integration.TestRunBinaryNotFoundAbsolute)
    test(integration.TestRunBinaryInParentFolder)
    test(integration.TestRunQuiet)
    test(integration.TestClean)

    test(integration.TestUpdateScripts)

    cmd.Main.make().tests(test)

  fun @runtime_override_defaults(rto: RuntimeOptions) =>
    rto.ponynoblock = true
