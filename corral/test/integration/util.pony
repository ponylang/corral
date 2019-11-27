use "cli"
use "ponytest"
use "../../util"

interface val Checker
  fun apply(h: TestHelper, ar: ActionResult)

primitive Execute
  fun apply(h: TestHelper, args: Array[String] val, checker: (Checker | None) = None) =>
    try
      let evars = EnvVars(h.env.vars)
      let corral_bin = evars.get_or_else("CORRAL_BIN", "corral")
      let corral_prog = Program(h.env, corral_bin)?
      let corral_cmd = Action(corral_prog, args, h.env.vars)
      match checker
      | let chk: Checker => Runner.run(corral_cmd, {(ar: ActionResult) => chk(h, ar)} iso)
      | None => Runner.run(corral_cmd, {(ar: ActionResult) => None} iso)
      end
    else
      h.fail("failed to create corral Program")
    end
