use "collections"
use "../utils"

class Version is (ComparableMixin[Version] & Hashable & Stringable)
  var major: U64 = 0
  var minor: U64 = 0
  var patch: U64 = 0
  let pr_fields: Array[PreReleaseField] = Array[PreReleaseField]
  let build_fields: Array[String] = Array[String]
  let errors: Array[String] = Array[String]

  new create(
    major': U64,
    minor': U64 = 0,
    patch': U64 = 0,
    pr_fields': Array[PreReleaseField] = Array[PreReleaseField],
    build_fields': Array[String] = Array[String]
  ) =>
    major = major'
    minor = minor'
    patch = patch'
    pr_fields.append(pr_fields')
    build_fields.append(build_fields')
    errors.append(ValidateFields(pr_fields, build_fields))

  fun compare(that: Version box): Compare =>
    CompareVersions(this, that)

  fun hash(): USize =>
    string().hash()

  fun is_valid(): Bool =>
    errors.size() == 0

  fun string(): String iso^ =>
    let result = recover String(5) end // we always need at least 5 characters ("0.0.0")

    result.append(major_minor_patch_string())

    if (pr_fields.size() > 0) then
      result.append("-" + pre_release_string())
    end

    if (build_fields.size() > 0) then
      result.append("+" + build_string())
    end

    result

  fun major_minor_patch_string(): String =>
    ".".join([major; minor; patch].values())

  fun pre_release_string(): String =>
    ".".join(pr_fields.values())

  fun build_string(): String =>
    ".".join(build_fields.values())
