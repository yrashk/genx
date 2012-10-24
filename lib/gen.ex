defmodule GenX.Gen do
  def defhandler(callback, send, f, options) do
    defhandler(callback, send, f, options, [])
  end
  def defhandler(callback, send, {function,l,nil}, options, extras) do
    defhandler(callback, send, {function,l,[]}, options, extras)
  end
  def defhandler(callback, {m,f}, {function,_, arguments}, options, extras) do
    if is_atom(arguments), do: arguments = []
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
        lc argn inlist :lists.seq(1, length(arguments)) do
          {binary_to_atom("arg_#{argn}"), 0, :quoted}
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
    extra_handle_arguments = lc e inlist (extras[:handle] || []), do: options[e] || {:_, 0, :quoted}
    before_request_send_arguments = extras[:before_request] || []
    extra_send_arguments = extras[:send] || []
    args = List.concat [server|before_request_send_arguments], 
                       [message_request|extra_send_arguments]
    quote do
      def unquote(callback)(unquote(request),
                             unquote_splicing(extra_handle_arguments),
                             unquote(state)), do: unquote(options[:do])
      unless Module.defines?(__MODULE__, 
                                      {unquote(export[:name]), 
                                       unquote(arity)}) and
             unquote(export[:name]) !== false do
        def unquote(export[:name])(unquote_splicing(full_arguments)) do
          unquote(m).unquote(f)(unquote_splicing(args))
        end
        defoverridable [{unquote(export[:name]), unquote(arity)}]
      end
    end

  end

end
