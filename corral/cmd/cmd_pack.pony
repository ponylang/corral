use "cli"
use "collections"
use "files"
use "logger"
use "../archive"
use "../bundle"
use "../util"
use "../vcs"

class CmdPack is CmdType
  let _output: String

  new create(cmd: Command) =>
    _output = cmd.arg("output").string()

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("pack: from " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      try
        let path = FilePath(project.auth, _output)?
        if not path.mkdir() then
          ctx.uout(Error) and
            ctx.uout.log("pack: unable to create " + _output)
        end

        let car_name: String = bundle.info.name + "-" + bundle.info.version + ".car"
        let car_path = Path.join(_output, car_name)
        let car_file_path = FilePath(project.auth, car_path)?

        let corral_file = project.dir.join(Files.bundle_filename())?

        let encoder = ArchiveEncoder(project.dir)?
        encoder.add(corral_file)?

        let sorted_packages = Sort[Array[String], String](bundle.packages)
        for package in sorted_packages.values() do
          encoder.add(FilePath(project.dir, package)?)?
        end

        encoder.write(car_file_path)?
      else
        // TODO STA
        ctx.uout(Error) and ctx.uout.log("pack: better message here")
        ctx.env.exitcode(1)
      end
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log("pack: " + err)
      ctx.env.exitcode(1)
    end
