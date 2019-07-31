interface ComparableMixin[A: Comparable[A] #read] is Comparable[A]
  fun compare(that: box->A): Compare

  fun lt(that: box->A): Bool =>
    compare(that) is Less

  fun le(that: box->A): Bool =>
    let c = compare(that)
    (c is Less) or (c is Equal)

  fun gt(that: box->A): Bool =>
    compare(that) is Greater

  fun ge(that: box->A): Bool =>
    let c = compare(that)
    (c is Greater) or (c is Equal)

  fun eq(that: box->A): Bool =>
    compare(that) is Equal

  fun ne(that: box->A): Bool =>
    not eq(that)
