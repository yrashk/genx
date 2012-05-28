defmodule GenEvent.Behavior do
 defmacro __using__(_) do
    quote do
      @behavior :gen_event

      def handle_event(_event, state) do
        { :ok, state }
      end

      def handle_call(_req, state) do
        { :ok, :ok, state }
      end

      def handle_info(_msg, state) do
        { :ok, state }
      end

      def terminate(reason, state) do
        :error_logger.error_report('#{inspect __MODULE__} crashed:\n#{inspect reason}')
        :error_logger.error_report('#{inspect __MODULE__} snapshot:\n#{inspect state}')
        :ok
      end

      def code_change(_old, state, _extra) do
        { :ok, state }
      end

      defoverridable [handle_event: 2, handle_call: 2, handle_info: 2, terminate: 2, code_change: 3]
    end
 end
end
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
