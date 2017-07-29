
primitive _PathNameEncoder
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
    let alphanums = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".array()
    alphanums.contains(c)
