
use @system[I32](command: Pointer[U8] tag)

interface _ExitCodeFn
  fun ref apply(code: I32)

// TODO: Remove Shell hack in favor of cap-based implementations of actions.
// TODO: see process/process_monitor.pony

primitive Shell
  fun tag apply(
    command: String,
    exit_code_fn: (_ExitCodeFn | None) = None
  )? =>
    var rc = @system(command.cstring())
    if (rc < 0) or (rc > 255) then rc = 1 end // clip out-of-bounds exit codes
    try (exit_code_fn as _ExitCodeFn)(rc) end
    if rc != 0 then error end

  fun tag from_array(
    command_args: Array[String] box,
    exit_code_fn: (_ExitCodeFn | None) = None
  )? =>
    var command = recover trn String end
    for arg in command_args.values() do
      command.append(escape_arg(arg))
      command.push(' ')
    end
    apply(consume command, exit_code_fn)

  fun tag escape_arg(arg: String): String =>
    "'" + arg.clone().>replace("'", "'\\''") + "'"
