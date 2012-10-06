defmodule GenX.GenServer do
  @moduledoc """
  GenX.GenServer is a convenience helper for building gen_servers.

  ### Example

     defmodule MyServer do
       use GenServer.Behaviour
       import GenX.GenServer

       ...
     end
  """
  import GenX.Gen

  options_doc = """
  * state: matches the state
  * export:
    * when `false`, no exported function to call into the server will be created
    * when an atom (such as MyServer), the exported function
      will call into a named server instead of taking a pid/name
      as an argument

      ### Example:

        defmodule MyServer do
         use GenServer.Behaviour
         import GenX.GenServer

         defcall test, export: MyServer
        end

      In this case, MyServer.test/0 will be created which
      will be attempting to call named server `MyServer`
    * when a keyword, can contain following options:
      * server: see above about the atom variant
      * timeout: custom call timeout (default is 5000 ms) [applicable to defcall only]
      * name: custom name of the exported function
  """

  handle_call_doc = """
  defcall defines a handle_call callback with
  an (optional) exported function to call into
  the server.

  The call is normally defined in a form of a function,
  such as:

     defcall call1, do: ...
     defcall call2(value), do: ...

  The above definitions will translate to handle_calls
  that handle :call1 and {:call2, value} messages.

  These definitions will also create `call1` and `call2`
  functions that will call into the server.  

  defcall also takes following options:

  #{options_doc}

  The return values of a defcall's body matches to the one
  expected in handle_call callbacks.
  ### Example

     defmodule MyServer do
       use GenServer.Behaviour
       import GenX.GenServer

       defcall test, state: state, do: {:reply, :ok, state}
     end
  """

  @doc handle_call_doc
  defmacro defcall(call, options, body) do
     unless is_list(options[:export]) or options[:export] == nil, do: options = Keyword.put options, :export, [server: options[:export]]
     send = case (options[:export]||[])[:timeout] do
                 nil -> []
                 v -> [v]
            end
    defhandler(:handle_call, {:gen_server, :call}, call, Keyword.from_enum(options ++ body), [handle: [:from], send: send])
  end

  @doc handle_call_doc
  defmacro defcall(call, body) do
     defhandler(:handle_call, {:gen_server, :call}, call, body, [handle: [:from]])
  end

  handle_cast_doc = """
  defcast defines a handle_cast callback with
  an (optional) exported function to cast into
  the server.

  The cast is normally defined in a form of a function,
  such as:

     defcast cast1, do: ...
     defcast cast2(value), do: ...

  The above definitions will translate to handle_casts
  that handle :cast1 and {:cast2, value} messages.

  These definitions will also create `cast1` and `cast2`
  functions that will cast into the server.  

  defcast also takes following options:

  #{options_doc}

  The return values of a defcast's body matches to the one
  expected in handle_cast callbacks.
  ### Example

     defmodule MyServer do
       use GenServer.Behaviour
       import GenX.GenServer

       defcast test, state: state, do: {:noreply, state}
     end
  """

  @doc handle_cast_doc
  defmacro defcast(cast, options, body) do
     defhandler(:handle_cast, {:gen_server, :cast}, cast, Keyword.from_enum(options ++ body))
  end
  @doc handle_cast_doc
  defmacro defcast(cast, body) do
     defhandler(:handle_cast, {:gen_server, :cast}, cast, body)
  end

  handle_info_doc = """
  definfo defines a handle_info callback with
  an (optional) exported function to info into
  the server.

  The info is normally defined in a form of a function,
  such as:

     definfo info1, do: ...
     definfo info2(value), do: ...

  The above definitions will translate to handle_infos
  that handle :info1 and {:info2, value} messages.

  These definitions will also create `info1` and `info2`
  functions that will send a message into the server.  

  definfo also takes following options:

  #{options_doc}

  The return values of a definfo's body matches to the one
  expected in handle_info callbacks.
  ### Example

     defmodule MyServer do
       use GenServer.Behaviour
       import GenX.GenServer

       definfo test, state: state, do: {:noreply, state}
     end
  """

  @doc handle_info_doc
  defmacro definfo(info, options, body) do
     defhandler(:handle_info, {:erlang, :send}, info, Keyword.from_enum(options ++ body))
  end
  @doc handle_info_doc
  defmacro definfo(info, body) do
      defhandler(:handle_info, {:erlang, :send}, info, body)
  end

end
