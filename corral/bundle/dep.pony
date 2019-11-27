use "files"
use "json"
use "../util"
use "debug"

class val Locator
  """
  Encapsulation of the bundle dependency's locator string, parsed into distinct
  fields.
    locator := repo_path[.suffix][/bundle_path]
  """
  let repo_path: String
  let vcs_suffix: String
  let bundle_path: String

  new val create(loc: String) =>
    let suffixes = [".git"; ".hg"; ".bzr"; ".svn"]
    var rp = ""
    var vs = ""
    var bp = ""
    for s in suffixes.values() do
      let parts = loc.split_by(s)
      if parts.size() == 2 then try
        rp = parts(0)?
        vs = s
        let p = parts(1)?
        bp = if (p.size() > 0) and (p(0)? == '/') then p.trim(1) else p end
        // TODO: strip any leading scheme://
        //Debug.out(" loc:: rp:" + rp + " vs:" + vs + )
        break
      end end
    end
    if vs == "" then
      rp = loc
    end
    repo_path = rp
    vcs_suffix = vs
    bundle_path = bp

  fun path(): String =>
    Path.join(repo_path, bundle_path)

  fun string(): String =>
    Path.join(repo_path + vcs_suffix, bundle_path)

  fun is_vcs(): Bool => vcs_suffix != ""

  fun is_local(): Bool =>
    let path_pre = repo_path.trim(1,0)
    (path_pre == ".") or (path_pre == "/")

  fun is_remote_vcs(): Bool => is_vcs() and not is_local()

  fun is_local_vcs(): Bool => is_vcs() and is_local()

  fun is_local_direct(): Bool => not is_vcs() and is_local()

class Dep
  """
  Encapsulation of a dependency within a Bundle, encompassing both dep and lock
  data and coordinated operations.
  """
  let bundle: Bundle box
  let data: DepData box
  let lock: LockData
  let locator: Locator

  new create(bundle': Bundle box, data': DepData box, lock': LockData) =>
    bundle = bundle'
    data = data'
    lock = lock'
    locator = Locator(data.locator)
    //bundle.env.out.print("Locator: " + locator.repo_path + " " +
    //  locator.vcs_suffix + " " + locator.bundle_path)

  fun box name(): String =>
    locator.path()

  fun box flat_name(): String =>
    _Flattened(locator.path())

  fun box repo(): String =>
    locator.repo_path + locator.vcs_suffix

  fun box flat_repo(): String =>
    _Flattened(repo())

  fun box version(): String =>
    if lock.revision != "" then
      lock.revision
    elseif data.version != "" then
      data.version
    else
      "master"
    end

  fun box vcs(): String =>
    locator.vcs_suffix.trim(1)

  fun ref lock_version(ver: String) =>
    lock.locator = data.locator
    lock.revision = ver

primitive _Flattened
  fun apply(path: String): String val =>
    let dash_code: U8 = 95 // '_'
    let path_name_arr = recover val
      var acc: Array[U8] = Array[U8]
      for char in path.array().values() do
        if _is_alphanum(char) then
          acc.push(char)
        else
          try // we know we don't index out of bounds
            if acc.size() == 0 then
              acc.push(dash_code)
            elseif acc(acc.size() - 1)? != dash_code then
              acc.push(dash_code)
            end
          end
        end
      end
      //acc.append(path.hash().string())
      consume acc
    end
    String.from_array(consume path_name_arr)

  fun _is_alphanum(c: U8): Bool =>
    let alphanums =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".array()
    alphanums.contains(c)
