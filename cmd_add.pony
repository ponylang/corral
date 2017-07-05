use "cli"
use "json"
use "logger"

primitive CmdAddGithub
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("add/github: " + cmd.string())

    let bd = BundleData.empty()
    bd.source = "github"
    bd.locator = cmd.arg("repo").string()
    bd.subdir = cmd.option("subdir").string()
    bd.version = ""
    bd.revision = cmd.option("tag").string()

    log.log("Adding: " + bd.json().string())
    try
      let project = ProjectFile.load_project(env, log)
      project.add_bundle(bd)
      project.save()
      //project.fetch() // TODO: just fetch this bundle
    end

primitive CmdAddGit
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("add/git: " + cmd.string())

    let bd = BundleData.empty()
    bd.source = "git"
    bd.locator = cmd.arg("path").string()
    //bd.subdir = cmd.option("subdir").string()
    bd.version = ""
    bd.revision = cmd.option("tag").string()

    log.log("Adding: " + bd.json().string())
    try
      let project = ProjectFile.load_project(env, log)
      project.add_bundle(bd)
      project.save()
      //project.fetch() // TODO: just fetch this bundle
    end

primitive CmdAddLocal
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("add/local: " + cmd.string())

    let bd = BundleData.empty()
    bd.source = "local"
    bd.locator = cmd.arg("path").string()
    //bd.subdir = cmd.option("subdir").string()
    //bd.version = ""
    //bd.revision = cmd.option("tag").string()

    log.log("Adding: " + bd.json().string())
    try
      let project = ProjectFile.load_project(env, log)
      project.add_bundle(bd)
      project.save()
      //project.fetch() // TODO: just fetch this bundle
    end
