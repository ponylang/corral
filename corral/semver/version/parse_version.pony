use "../utils"

primitive ParseVersion
  fun apply(s: String): Version =>
    let v = Version(0)

    if (s == "") then
      v.errors.push("version string blank")
      return v
    end

    try
      let head_and_build = s.split("+", 2)
      let head_and_pre_rel = head_and_build(0)?.split("-", 2)

      let maj_min_pat = recover box head_and_pre_rel(0)?.split(".") end
      if (maj_min_pat.size() != 3) then
        v.errors.push("expected head of version string to be of the form 'major.minor.patch'")
        return v
      end

      for m in maj_min_pat.values() do
        if ((m == "") or (not Strings.contains_only(m, Consts.nums()))) then
          v.errors.push("expected major, minor and patch to be numeric")
          return v
        end
      end

      v.major = maj_min_pat(0)?.u64()?
      v.minor = maj_min_pat(1)?.u64()?
      v.patch = maj_min_pat(2)?.u64()?

      if (head_and_pre_rel.size() == 2) then
        for p in head_and_pre_rel(1)?.split(".").values() do
          if ((p != "") and (Strings.contains_only(p, Consts.nums()))) then
            if ((p.size() > 1) and (p.compare_sub("0", 1) is Equal)) then
              v.errors.push("numeric pre-release fields cannot have leading zeros")
            else
              v.pr_fields.push(p.u64()?)
            end
          else
            v.pr_fields.push(p)
          end
        end
      end

      if (head_and_build.size() == 2) then
        v.build_fields.append(head_and_build(1)?.split("."))
      end
    else
      v.errors.push("unexpected internal error")
    end

    v.errors.append(ValidateFields(v.pr_fields, v.build_fields))
    v
