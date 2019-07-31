use "../utils"

primitive CompareVersions
  fun apply(v1: Version box, v2: Version box): Compare =>
    let heads = [
      (v1.major, v2.major)
      (v1.minor, v2.minor)
      (v1.patch, v2.patch)
    ]

    for (h1, h2) in heads.values() do
      if (h1 != h2) then return h1.compare(h2) end
    end

    let p1s = v1.pr_fields.size()
    let p2s = v2.pr_fields.size()

    if ((p1s == 0) and (p2s == 0)) then return Equal end
    if ((p1s == 0) and (p2s > 0)) then return Greater end
    if ((p1s > 0) and (p2s == 0)) then return Less end

    for (pr1, pr2) in ZipIterator[PreReleaseField, PreReleaseField](v1.pr_fields.values(), v2.pr_fields.values()) do
      match _compare_pr_Fields(pr1, pr2)
      | Less => return Less
      | Greater => return Greater
      end
    end

    p1s.compare(p2s)

  fun _compare_pr_Fields(p1: PreReleaseField, p2: PreReleaseField): Compare =>
    match (p1, p2)
    | (let u1: U64, let s2: String) => Less
    | (let s1: String, let u2: U64) => Greater
    | (let u1: U64, let u2: U64) => u1.compare(u2)
    | (let s1: String, let s2: String) => s1.compare(s2)
    else
      Equal // should never get here but compiler complains without it
    end
