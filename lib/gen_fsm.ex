defmodule GenFsm.Behaviour do
 defmacro __using__(_) do
    quote do
      @behaviour :gen_fsm

      def handle_event(_event, state_name, state) do
        { :next_state, state_name, state }
      end

      def handle_sync_event(_event, _from, state_name, state) do
        { :next_state, state_name, state }
      end

      def handle_info(_msg, state_name, state) do
        { :next_state, state_name, state }
      end

      def terminate(reason, state_name, state) do
        :error_logger.error_report('#{inspect __MODULE__} crashed:\n#{inspect reason}')
        :error_logger.error_report('#{inspect __MODULE__} snapshot:\n#{inspect state_name}/#{inspect state} ')
        :ok
      end

      def code_change(_old, state_name, state, _extra) do
        { :ok, state_name, state }
      end

      defoverridable [handle_event: 3, handle_sync_event: 4, handle_info: 3, terminate: 3, code_change: 4]
    end
 end
end
defmodule GenX.GenFsm do
  import GenX.Gen

   defp _defevent({:"/",_,[{state_name,_,_},event]}, options, body) do
        _defevent(event, Keyword.merge(options, [in: state_name]), body)
   end
   defp _defevent(event, options, body) do
     state_name = options[:in]
     if (not (options[:all_states]||false) and state_name == nil), do: throw(:badarg)
     {event_sender, handler, handle} = case ({options[:all_states]||false,options[:sync]||false}) do
               {false,false} -> {:send_event, state_name, []}
               {false,true} -> {:sync_send_event, state_name, [:from]}
               {true, false} -> {:send_all_state_event, :handle_event, [:state_name]}
               {true, true} -> {:sync_send_all_state_event, :handle_sync_event, [:from, :state_name]}
             end
    defhandler(handler, {:gen_fsm, event_sender}, event, Keyword.from_enum(options ++ body), [handle: handle])
   end

   defmacro defevent(event, options, body) do
     _defevent(event, options, body)
   end

   defmacro defevent(event, options) do
    _defevent(event, options, [do: options[:do]])
   end

   defmacro definfo(info, options, body) do
    defhandler(:handle_info, {:erlang, :send}, info, Keyword.from_enum(options ++ body), [handle: [:state_name]])
   end

   defmacro definfo(info, body) do
    defhandler(:handle_info, {:erlang, :send}, info, body, [handle: [:state_name]])
   end


end
