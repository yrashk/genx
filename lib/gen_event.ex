defmodule GenX.GenEvent do
  import GenX.Gen

  defmacro defevent(event, options, body) do
    notify = case (options[:sync]||false) do
                true -> :sync_notify
                false -> :notify
           end
    defhandler(:handle_event, {:gen_event, notify}, event, Keyword.from_enum(options ++ body))
  end

  defmacro defevent(event, body) do
    defhandler(:handle_event, {:gen_event, :notify}, event, body)
  end

  defmacro defcall(call, options, body) do
    send = case (options[:export]||[])[:timeout] do
                 nil -> []
                 v -> [v]
            end
    defhandler(:handle_call, {:gen_event, :call}, call, Keyword.from_enum(options ++ body), [before_request: [(quote do: __MODULE__)], send: send])
  end

  defmacro defcall(call, body) do
    defhandler(:handle_call, {:gen_event, :call}, call, body, [before_request: [(quote do: __MODULE__)]])
  end

  defmacro definfo(info, options, body) do
    defhandler(:handle_info, {:erlang, :send}, info, Keyword.from_enum(options ++ body))
  end

  defmacro definfo(info, body) do
    defhandler(:handle_info, {:erlang, :send}, info, body)
  end

end
