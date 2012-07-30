defmodule Application do
  @moduledoc "Application startup and shutdown functionality"

  defdelegate [load(app_descr), load(app_descr, distributed),
               get_application, get_application(pid_or_module),
               loaded_applications, permit(application, permission), 
               stop(application), takeover(application, type), unload(application)], to: :application

  defdelegate [running_applications, running_applications(timeout)], to: :application, as: :which_applications
  
  @doc """
  `Application.start/1` and `Application.start/2` are used to start applications. They are similar to `:application.start/1` and
  `:application.start/2`, however, they support starting dependencies.
  
  Allowed options (`start/2`):

  * `:dependenices` (boolean): should dependencies be recursively started if required. Returns `{:error, {:not_started, required_app}}` if 
    `false`. Default: `true`
  * `:type` (atom): restart type (:temporary, :transient, :permanent). Default: `temporary`
    Excerpt from Erlang/OTP documentation:
     * If a permanent application terminates, all other applications and the entire Erlang node are also terminated.
     * If a transient application terminates with Reason == normal, this is reported but no other applications are terminated. 
       If a transient application terminates abnormally, all other applications and the entire Erlang node are also terminated.
     * If a temporary application terminates, this is reported but no other applications are terminated.

  """
  def start(application), do: start(application, [dependencies: true])
  def start(application, options) do
    unless options[:type], do: options = Keyword.put(options, :type, :temporary)

    case {options[:dependencies], :application.start(application, options[:type])} do
      {true, {:error, {:not_started, dep}}} ->
        start(dep, options)
        start(application, options)
      {_, {:error, {:already_started, _}}} -> :ok
      {_, other} -> other
    end
  end

  def environment(application) do
      Keyword.from_enum(:application.get_all_env(application))
  end

  def environment do
      Keyword.from_enum(:application.get_all_env)
  end
  
end

defmodule Application.Behavior do
 defmacro __using__(_) do
    quote do
      @behavior :application

      def stop(_state), do: :ok

      defoverridable [stop: 1]
    end
 end
end
