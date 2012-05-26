defmodule GenX.GenServer do

  defp _defhandler(callback, send, f, options) do
     _defhandler(callback, send, f, options, [])
  end
  defp _defhandler(callback, send, {function,l,nil}, options, extras) do
    _defhandler(callback, send, {function,l,[]}, options, extras)
  end
  defp _defhandler(callback, {m,f}, {function,_, arguments}, options, extras) do
    state = options[:state] || {:_, 0, :quoted}
    export_option = case options[:export] do
                         nil -> []
                         keyword when is_list(keyword) -> keyword
                         value -> [server: value]
                    end
    export = Keyword.merge [server: :server, name: {function, 0, nil}], export_option
    {function_name, _, _} = export[:name]
    export = Keyword.put export, :name, function_name
    request =
    case arguments do
      [] -> function
      _  -> {:{}, 0, [function|arguments]}
    end
    arguments_stub = 
        lc argn in :lists.seq(1, length(arguments)) do
          {list_to_atom('arg_' ++ integer_to_list(argn)), 0, :quoted}
        end
    full_arguments =
        case export[:server] do
          :server -> [{:server, 0, :quoted}]
          _ -> []
        end ++ arguments_stub
    arity = length(full_arguments)
    message_request =
    case arguments_stub do
      [] -> function
      _ -> {:{}, 0, [function|arguments_stub]}
    end
    server =
    case export[:server] do
              :server -> {:server, 0, :quoted}
              val -> val
    end
    extra_handle_arguments = lc e in (extras[:handle] || []), do: options[e] || {:_, 0, :quoted}
    extra_send_arguments = extras[:send] || []
    quote do
      def unquote(callback).(unquote(request),
                             unquote_splicing(extra_handle_arguments),
                             unquote(state)), do: unquote(options[:do])
      unless Module.function_defined?(__MODULE__, 
                                      {unquote(export[:name]), 
                                        unquote(arity)}) and
             unquote(export[:name]) !== false do
              def unquote(export[:name]).(unquote_splicing(full_arguments)) do
                  :erlang.apply(unquote(m),unquote(f),[unquote(server), unquote(message_request)|unquote(extra_send_arguments)])
              end
      end

    end

  end

  defmacro defcall(call, options, body) do
     send = case (options[:export]||[])[:timeout] do
                 nil -> []
                 v -> [v]
            end
    _defhandler(:handle_call, {:gen_server, :call}, call, Keyword.from_enum(options ++ body), [handle: [:from], send: send])
  end
  defmacro defcall(call, body) do
     _defhandler(:handle_call, {:gen_server, :call}, call, body, [handle: [:from]])
  end

  defmacro defcast(cast, options, body) do
     _defhandler(:handle_cast, {:gen_server, :cast}, cast, Keyword.from_enum(options ++ body))
  end
  defmacro defcast(cast, body) do
     _defhandler(:handle_cast, {:gen_server, :cast}, cast, body)
  end

  defmacro definfo(info, options, body) do
     _defhandler(:handle_info, {:erlang, :send}, info, Keyword.from_enum(options ++ body))
  end
  defmacro definfo(info, body) do
      _defhandler(:handle_info, {:erlang, :send}, info, body)
  end

end
