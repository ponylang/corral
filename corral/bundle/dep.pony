use "collections"
use "files"
use "json"
use "../util"
use su="../semver/utils"

class val Locator is (su.ComparableMixin[Locator] & Hashable & Stringable)
  """
  Encapsulation of the bundle dependency's locator string, parsed into distinct
  fields.
    locator := repo_path[.vcs_suffix][/bundle_path]
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
        //Debug.out(" loc:: rp:" + rp + " vs:" + vs  + " bp:" + bp)
        break
      end end
    end
    if vs == "" then
      bp = loc  // With no vcs, the locator is the local bundle path
    end
    repo_path = rp
    vcs_suffix = vs
    bundle_path = bp

  fun path(): String =>
    """Returns a unique name for this locator without the vcs suffix."""
    Path.join(repo_path, bundle_path)

  fun flat_name(): String =>
    _Flattened(path())

  fun string(): String iso^ =>
    """Returns the full string for of this locator."""
    Path.join(repo_path + vcs_suffix, bundle_path).clone()

  fun compare(that: Locator box): Compare =>
    if (repo_path != that.repo_path) then return repo_path.compare(that.repo_path) end
    if (vcs_suffix != that.vcs_suffix) then return vcs_suffix.compare(that.vcs_suffix) end
    bundle_path.compare(that.bundle_path)

  fun hash(): USize =>
    repo_path.hash() xor vcs_suffix.hash() xor bundle_path.hash()

  fun is_vcs(): Bool => vcs_suffix != ""

  fun is_local(): Bool => (repo_path == "") and (vcs_suffix == "")

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

  fun name(): String =>
    locator.path()

  fun repo(): String =>
    locator.repo_path + locator.vcs_suffix

  fun flat_repo(): String =>
    _Flattened(repo())

  fun version(): String => data.version

  fun revision(): String =>
    if lock.revision != "" then
      lock.revision
    elseif data.version != "" then
      data.version
    else
      "master"
    end

  fun vcs(): String =>
    locator.vcs_suffix.trim(1)

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
