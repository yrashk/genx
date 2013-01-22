defmodule GenX.Gen do
  def defhandler(callback, send, f, options) do
    defhandler(callback, send, f, options, [])
  end
  def defhandler(callback, send, {function, meta, nil}, options, extras) do
    defhandler(callback, send, {function, meta, []}, options, extras)
  end
  def defhandler(callback, {m,f}, {function, meta, arguments} = name, options, extras) do
    if is_atom(arguments), do: arguments = []
    state = options[:state] || (quote do: _)
    export_option = case options[:export] do
                         nil -> []
                         keyword when is_list(keyword) -> keyword
                         value -> [server: value]
                    end
    export = Keyword.merge [server: :server, name: name], export_option
    {function_name, _, _} = export[:name]
    export = Keyword.put export, :name, function_name
    request =
    case arguments do
      [] -> function
      _  -> (quote do: {unquote_splicing([function|arguments])})
    end
    arguments_stub =
        lc argn inlist :lists.seq(1, length(arguments)) do
          quote do: var!(unquote(binary_to_atom("arg_#{argn}")), __MODULE__)
        end
    full_arguments =
        case export[:server] do
          :server -> [(quote do: server)]
          _ -> []
        end ++ arguments_stub
    arity = length(full_arguments)
    message_request =
    case arguments_stub do
      [] -> function
      _ -> (quote do: {unquote_splicing([function|arguments_stub])})
    end
    server =
    case export[:server] do
              :server -> (quote do: server)
              val -> val
    end
    extra_handle_arguments = lc e inlist (extras[:handle] || []), do: options[e] || (quote do: _)
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
