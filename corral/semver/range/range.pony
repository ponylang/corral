use "../version"

class Range is (Equatable[Range] & Stringable)
  let from: RangeBound box
  let to: RangeBound box
  let from_inc: Bool
  let to_inc: Bool

  // note: from > to will result in undefined behavior
  //       decided not to raise an error for this situation
  new create(
    from': RangeBound box,
    to': RangeBound box,
    from_inc': Bool = true,
    to_inc': Bool = true)
  =>
    var from_equals_to = false

    match (from', to')
    | (let f: Version box, let t: Version box) =>
      from_equals_to = (f == t)
    end

    from = from'
    to = to'
    from_inc = ((from' is None) or from_equals_to or from_inc')
    to_inc = ((to' is None) or from_equals_to or to_inc')

  fun contains(v: Version): Bool =>
    match from
    | let f: Version box =>
      match v.compare(f)
      | Less => return false
      | Equal if (not from_inc) => return false
      end
    end

    match to
    | let t: Version box =>
      match v.compare(t)
      | Equal if (not to_inc) => return false
      | Greater => return false
      end
    end

    true

  fun eq(that: Range box): Bool =>
    RangeBoundsAreEqual(from, that.from) and
    RangeBoundsAreEqual(to, that.to) and
    (from_inc == that.from_inc) and
    (to_inc == that.to_inc)

  // note: ranges do not have to overlap to be merged
  fun merge(that: Range): Range =>
    (let m_from, let m_from_inc) = _merge_version_bounds(from, that.from, from_inc, that.from_inc, Less)
    (let m_to, let m_to_inc) = _merge_version_bounds(to, that.to, to_inc, that.to_inc, Greater)
    Range(m_from, m_to, m_from_inc, m_to_inc)

  fun _merge_version_bounds(
    vb1: RangeBound box,
    vb2: RangeBound box,
    inc1: Bool,
    inc2: Bool,
    v1_wins_if: Compare
  ): (RangeBound box, Bool) =>
    if ((vb1 is None) or (vb2 is None)) then return (None, true) end

    match (vb1, vb2)
    | (let v1: Version box, let v2: Version box) =>
      let c = v1.compare(v2)
      if (c is Equal) then return (v1, inc1 or inc2)
      elseif (c is v1_wins_if) then return (v1, inc1)
      else return (v2, inc2)
      end
    end

    (None, true) // should never get here but compiler complains without it

  fun overlaps(that: Range): Bool =>
    _from_less_than_to(this, that) and _from_less_than_to(that, this)

  fun _from_less_than_to(vr1: Range box, vr2: Range box): Bool =>
    match (vr1.from, vr2.to)
    | (let f: Version box, let t: Version box) =>
      match f.compare(t)
      | Equal if ((not vr1.from_inc) or (not vr2.to_inc)) => return false
      | Greater => return false
      end
    end
    true

  fun string(): String iso^ =>
    let result = recover String() end
    result.append(from.string() + " ")
    result.append(if (from_inc) then "(incl)" else "(excl)" end + " to ")
    result.append(to.string() + " ")
    result.append(if (to_inc) then "(incl)" else "(excl)" end)
    result
