defmodule GenX.GenServer do
  import GenX.Gen

  defmacro defcall(call, options, body) do
     unless is_list(options[:export]), do: options = Keyword.put options, :export, [server: options[:export]]
     send = case (options[:export]||[])[:timeout] do
                 nil -> []
                 v -> [v]
            end
    defhandler(:handle_call, {:gen_server, :call}, call, Keyword.from_enum(options ++ body), [handle: [:from], send: send])
  end
  defmacro defcall(call, body) do
     defhandler(:handle_call, {:gen_server, :call}, call, body, [handle: [:from]])
  end

  defmacro defcast(cast, options, body) do
     defhandler(:handle_cast, {:gen_server, :cast}, cast, Keyword.from_enum(options ++ body))
  end
  defmacro defcast(cast, body) do
     defhandler(:handle_cast, {:gen_server, :cast}, cast, body)
  end

  defmacro definfo(info, options, body) do
     defhandler(:handle_info, {:erlang, :send}, info, Keyword.from_enum(options ++ body))
  end
  defmacro definfo(info, body) do
      defhandler(:handle_info, {:erlang, :send}, info, body)
  end

end
