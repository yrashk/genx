defmodule GenX.Supervisor do
  use Supervisor.Behaviour

  defrecord Child, id: :undefined, start_func: :undefined, restart: :permanent,
                   shutdown: 5000, type: :undefined, modules: []

  defrecord Worker, id: :undefined, start_func: :undefined, restart: :permanent,
                    shutdown: 5000, modules: []

  defrecord Sup, id: :undefined, registered: false, restart_strategy: :undefined,
                        max_restarts: {1,60}, children: [], restart: :permanent,
                        shutdown: :infinity

  defrecord OneForOne, id: :undefined, registered: false,
                        max_restarts: {1,60}, children: [], restart: :permanent,
                        shutdown: :infinity

  defrecord OneForAll, id: :undefined, registered: false,
                        max_restarts: {1,60}, children: [], restart: :permanent,
                        shutdown: :infinity
  defrecord RestForOne, id: :undefined, registered: false,
                        max_restarts: {1,60}, children: [], restart: :permanent,
                        shutdown: :infinity
  defrecord SimpleOneForOne, id: :undefined, registered: false,
                        max_restarts: {1,60}, children: [], restart: :permanent,
                        shutdown: :infinity

  defprotocol Supervision do
    @only [Record, Tuple]
    def supervise(s)
  end

  defprotocol Supervisor do
    @only [Record, Tuple]
    def supervisor(s)
    def cast(s)
  end

  defimpl Supervision, for: Tuple do
    def supervise(t), do: t
  end

  defimpl Supervision, for: Child do
    def supervise(Child[id: id, start_func: :undefined]=c) when id !== :undefined and is_atom(id) do
        supervise(c.start_func({id, :start_link, []}))
    end
    def supervise(s) do
      spec = {s.id, s.start_func, s.restart, s.shutdown, s.type, s.modules}
      :ok = :supervisor.check_childspecs([spec])
      spec
    end
  end

  defimpl Supervision, for: Worker do    
    def supervise(s), do: GenX.Supervisor.supervise cast(s)
    defp cast(s) do
        Child.new(id: s.id, start_func: s.start_func,
                  restart: s.restart, shutdown: s.shutdown, type: :worker, modules: s.modules)
    end
  end

  defimpl Supervision, for: Sup do
    def supervise(s) do
      GenX.Supervisor.supervise Child.new(id: s.id, start_func: {GenX.Supervisor, :start_link, [s]}, 
                                          restart: s.restart, shutdown: s.shutdown, type: :supervisor, modules: [:dynamic])
    end
  end

  defimpl Supervisor, for: Sup do

    def supervisor(s) do
      {max_r, max_t} = s.max_restarts
      {{s.restart_strategy, max_r, max_t}, (lc child inlist s.children, do: GenX.Supervisor.supervise child)}
    end

    def cast(s), do: s

  end

  # tuple
  defimpl Supervisor, for: Tuple do    
    def supervisor(s), do: s
    def cast(s), do: s
  end

  # one_for_one
  defimpl Supervisor, for: OneForOne do    
    def supervisor(s), do: GenX.Supervisor.supervisor cast(s)
    def cast(s) do
        Sup.new(id: s.id, registered: s.registered, restart_strategy: :one_for_one,
                max_restarts: s.max_restarts, children: s.children, restart: s.restart,
                shutdown: s.shutdown)
    end
  end

  defimpl Supervision, for: OneForOne do    
    def supervise(s), do: GenX.Supervisor.supervise GenX.Supervisor.cast(s)
  end

  # one_for_all
  defimpl Supervisor, for: OneForAll do    
    def supervisor(s), do: GenX.Supervisor.supervisor cast(s)
    def cast(s) do
        Sup.new(id: s.id, registered: s.registered, restart_strategy: :one_for_all,
                max_restarts: s.max_restarts, children: s.children, restart: s.restart,
                shutdown: s.shutdown)
    end
  end

  defimpl Supervision, for: OneForAll do    
    def supervise(s), do: GenX.Supervisor.supervise GenX.Supervisor.cast(s)
  end

  # rest_for_one
  defimpl Supervisor, for: RestForOne do    
    def supervisor(s), do: GenX.Supervisor.supervisor cast(s)
    def cast(s) do
        Sup.new(id: s.id, registered: s.registered, restart_strategy: :rest_for_one,
                max_restarts: s.max_restarts, children: s.children, restart: s.restart,
                shutdown: s.shutdown)
    end
  end

  defimpl Supervision, for: RestForOne do    
    def supervise(s), do: GenX.Supervisor.supervise GenX.Supervisor.cast(s)
  end

  # simple_one_for_one
  defimpl Supervisor, for: SimpleOneForOne do    
    def supervisor(s), do: GenX.Supervisor.supervisor cast(s)
    def cast(s) do
        Sup.new(id: s.id, registered: s.registered, restart_strategy: :simple_one_for_one,
                max_restarts: s.max_restarts, children: s.children, restart: s.restart,
                shutdown: s.shutdown)
    end
  end

  defimpl Supervision, for: SimpleOneForOne do    
    def supervise(s), do: GenX.Supervisor.supervise GenX.Supervisor.cast(s)
  end


  defdelegate [supervise(s)], to: Supervision
  defdelegate [supervisor(s), cast(s)], to: Supervisor

  def start_link(sup, {module, args} // {__MODULE__, nil}) do
    case sup.registered do
      false ->
        :supervisor.start_link(module, {supervisor(sup), args})
      name ->
        :supervisor.start_link({:local, name}, module, {supervisor(sup), args})
    end
  end

  def init({sup, _args}) do
    {:ok, sup}
  end

end
