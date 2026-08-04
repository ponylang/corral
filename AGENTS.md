# Corral

The Pony dependency manager. It manages `corral.json` (deps, packages, info) and `lock.json` (locked revisions).

<!-- contributor-only -->
## Contributing with an AI assistant

This is a Pony project. The ponylang org maintains a set of LLM coding skills. Get set up with them before contributing:

- **Not set up yet?** Install them once:

  ```bash
  git clone https://github.com/ponylang/llm-skills.git
  cd llm-skills
  python install.py
  ```

- **Already set up?** Make sure you're on the latest. If you installed with the script above, `git pull` in the directory where you cloned `llm-skills` and the symlinked skills update automatically — if you set them up another way, refresh them however that setup expects.

See the [llm-skills README](https://github.com/ponylang/llm-skills) for details and other harnesses.

When you start working on this project, load the `pony-skills` skill — it tells your assistant which Pony skill to use for each task.

Read [CONTRIBUTING.md](CONTRIBUTING.md).
<!-- /contributor-only -->

## Prose model

If you are running on an Anthropic model, use `claude-opus-4-6` for writing comments, documentation, and other prose. Prose quality from Anthropic models dropped starting with Opus 4.7 and has gotten worse with each subsequent release.

## Building and testing

```
make                      # build the corral binary
make test                 # build + run unit and integration tests
make unit-tests           # unit tests only
make test-one t=TestName  # run a single test by name
make integration          # integration tests only (needs the built binary)
make clean                # remove build artifacts
make config=debug         # debug build
```

Corral builds with `ponyc` directly and has no corral dependencies — it bootstraps itself. The Makefile generates `version.pony` from `version.pony.in` and the `VERSION` file, so don't edit `version.pony` by hand. Integration tests find the built binary through the `CORRAL_BIN` environment variable the Makefile sets.

## Architecture

`Main` parses the CLI and hands off to `Executor`, which resolves directories, builds a `Context` and `Project`, and calls the chosen command. Each command implements the `CmdType` trait; most load a `Bundle` from the project, operate on it, and save. `_Updater` — the async actor behind `update` and `fetch` — walks the dependency graph transitively and chains each dep's VCS work as `RepoOperation` steps (sync → tag_query → checkout), each step spawning the next on completion. Commands receive a `VCSBuilder`, so a test can inject a double (`_RecordedVCS`) instead of running real VCS. Cloned repos live in a `_repos/` cache beside the bundle; checked-out workspaces go in `_corral/`.

## Testing

- Register new tests in `corral/test/_test.pony`, or they won't run.
- Name integration tests `integration/…` — the Makefile selects them with `--only`/`--exclude=integration`.
- `\nodoc\` on test classes.

## Conventions

- Log through the short-circuit form `ctx.log(Level) and ctx.log.log("message")`, so a filtered level never builds the string.
- Fallible operations return the value or a `String` error (for example `Project.load_bundle(): (Bundle iso^ | String)`); callers match `| let err: String =>`.
