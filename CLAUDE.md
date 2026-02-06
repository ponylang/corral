# Corral

Pony dependency manager. Manages `corral.json` (deps/packages/info) and `lock.json` (locked revisions) files.

## Building and Testing

```
make                  # build + test (unit + integration)
make unit-tests       # unit tests only
make integration      # integration tests only (requires built binary)
make test             # both unit and integration
make clean            # remove build artifacts
make config=debug     # debug build
```

Tests run via `ponyc` directly (no corral dependencies needed — it bootstraps itself). The Makefile generates `version.pony` from `version.pony.in` using the VERSION file.

Integration tests use the `CORRAL_BIN` env var (set by Makefile) to locate the built binary. Unit tests run in-process.

## Source Layout

```
corral/
  main.pony, cli.pony     -- Entry point and CLI spec (subcommands defined here)
  version.pony.in          -- Template, generates version.pony
  cmd/                     -- Command implementations
    cmd_type.pony          -- CmdType trait (requires_bundle, requires_no_bundle, apply)
    cmd_update.pony        -- CmdUpdate + _Updater actor (the most complex command)
    executor.pony          -- Resolves dirs, creates Context/Project, dispatches command
    context.pony           -- Context val: env, log, uout, nothing flag, repo_cache
    result_receiver.pony   -- CmdResultReceiver interface + NoOpResultReceiver
    repo.pony              -- RepoForDep: constructs Repo from dep + project
  bundle/                  -- Core data model
    bundle.pony            -- Bundle class: loads/saves corral.json + lock.json
    dep.pony               -- Dep class: wraps DepData + LockData + Locator
    data.pony              -- Data classes: BundleData, DepData, LockData, etc.
    locator.pony           -- Locator val: parses "repo_path[.vcs_suffix][/bundle_path]"
    project.pony           -- Project val + BundleDir + Files primitives
    json.pony              -- Bundle-specific JSON helpers
  vcs/                     -- VCS backends (git, hg, bzr, svn, none)
    vcs.pony               -- VCS interface, Repo class, RepoOperation interface
    vcs_builder.pony       -- VCSBuilder interface + CorralVCSBuilder
    git.pony               -- GitVCS (the only fully-featured one)
  semver/                  -- Semantic versioning (parsing, ranges, constraint solving)
  json/                    -- Custom JSON handling (not stdlib)
  util/                    -- Action (Program/Action/ActionResult/Runner), Copy, Log
  logger/                  -- Logger with levels (Error, Warn, Info, Fine)
  test/                    -- Test entry point + test utilities
    integration/           -- Integration tests (run built binary as subprocess)
    testdata/              -- Test fixture bundles (corral.json files, etc.)
```

## Key Architecture

- **CLI dispatch**: `Main` parses CLI -> `Executor` resolves dirs + creates `Context`/`Project` -> calls `command(ctx, project, vcs_builder, result_receiver)`
- **Commands**: Each implements `CmdType` trait. Most load a `Bundle` from the project, operate on it, then save.
- **_Updater**: The core actor for `update`/`fetch`. Walks deps transitively, chains VCS operations (sync -> tag_query -> checkout) per dep, collects tags, resolves versions, saves locks. Async via actor behaviors.
- **VCS operations**: Chained as `RepoOperation` lambdas: `sync_op -> tag_query_op -> checkout_op`. Each VCS step spawns the next on completion.
- **VCSBuilder abstraction**: Commands receive a `VCSBuilder` interface, enabling test doubles. Unit tests use `_RecordedVCS` to count operations without real VCS calls.
- **Bundle search**: Without `--bundle_dir`, searches up directory tree for `corral.json`. With it, looks only in the specified dir.
- **Repo cache**: `_repos/` dir alongside the bundle stores cloned repos. `_corral/` dir stores checked-out workspaces.

## Testing Patterns

- **Unit tests** (`cmd/_test_cmd_update.pony`): Use fake VCS (`_RecordedVCS`) to verify operation counts (syncs, tag queries, checkouts) without network. Test data from `test/testdata/`.
- **Integration tests** (`test/integration/`): Run the actual corral binary via `Execute` helper (uses `ProcessMonitor`). `DataClone` copies test fixtures to temp dirs. Tests use `h.long_test()` with 30s timeouts.
- **Test registration**: `test/_test.pony` is the test Main. Unit tests listed directly; cmd tests delegated via `cmd.Main.make().tests(test)`.
- **Naming**: Integration tests named `"integration/..."`, unit tests named `"cmd/update/..."` etc. `\nodoc\` annotation on test classes.

## Conventions

- Private fields prefixed with `_`. Private types prefixed with `_`.
- `\nodoc\` annotation on test actors/classes.
- Constructors often use `param'` (prime) naming for constructor params that shadow field names.
- Logging pattern: `ctx.log(Level) and ctx.log.log("message")` — the `and` short-circuits so string isn't built if level is filtered.
- Error returns as union types: `(SuccessType | ErrorType)` rather than exceptions, except `?` for simple lookup failures.
- `iso` bundles passed between actors via `consume`.
- Capabilities: `Bundle` created as `iso`, consumed into `ref` by actors. `Context`, `Project`, `Locator`, `VCS`, `Repo`, `Action`, `Program` are all `val`.
