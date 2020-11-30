use "collections"

primitive Strings
  fun contains_only(s: String, codepoints: Set[U32]): Bool =>
    for codepoint in s.values() do
      if (not codepoints.contains(codepoint)) then return false end
    end
    true
