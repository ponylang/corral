use "collections"

// TODO: review the ponylang discussion around constants
//       the runtime cost here every time is silly for what are supposed to be fixed values
primitive Consts
  fun alphas(): Set[U8] =>
    Set[U8].>
      union("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-".values())

  fun nums(): Set[U8] =>
    Set[U8].>union("0123456789".values())

  fun alphanums(): Set[U8] =>
    Set[U8].>
      union(alphas().values()).>
      union(nums().values())
