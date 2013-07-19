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
    unless is_list(options[:export]) or options[:export] == nil, do: options = Keyword.put options, :export, [server: options[:export]]
    send = case (options[:export]||[])[:timeout] do
             nil -> []
             v -> [v]
           end
    defhandler(handler, {:gen_fsm, event_sender}, event, Keyword.from_enum(options ++ body), [handle: handle, send: send])
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
