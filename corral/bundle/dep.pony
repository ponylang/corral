use "collections"
use "files"
use "../json"
use su="../semver/utils"

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

  fun name(): String => locator.path()

  fun repo(): String => locator.repo_path + locator.vcs_suffix

  fun flat_repo(): String => _Flattened(repo())

  fun version(): String => data.version

  fun revision(): String => lock.revision

  fun vcs(): String => locator.vcs_suffix.trim(1)


