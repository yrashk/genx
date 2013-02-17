defmodule GenX.GenServer.Sample do
 import GenX.GenServer              
 use GenServer.Behaviour             
 alias :gen_server, as: GS

 defcall call, do: {:reply, :call, nil}
 defcall call(a), do: {:reply, {:call, a}, nil}
 defcall call(a, b), do: {:reply, {:call, a, b}, nil}
 defcall call(a, b, c), do: {:reply, {:call, a, b, c}, nil}

 defcall get_state, state: state, do: {:reply, state, state}
 defcall set_state(state), do: {:reply, :ok, state}

 defcall async_reply, from: from, state: state do
   spawn(fn() -> GS.reply(from, :ok) end)
   {:noreply, state}
 end

 defcall private_call, export: false, state: state, do: {:reply, :ok, state}

 defcall named_call, export: SampleServer, state: state, do: {:reply, :ok, state}

 defcall custom_call_export, export: [name: custom_call_export_indeed], state: state, do: {:reply, :custom, state}

 defcall timeout, export: [timeout: 1] do
   :timer.sleep(1000)
   {:reply, :ok, nil}
 end

 defcall named_timeout, export: [server: SampleServer, timeout: 1] do
   :timer.sleep(1000)
   {:reply, :ok, nil}
 end

 defcast cast, do: {:noreply, :casted}
 defcast cast(a), do: {:noreply, {:casted, a}}
 defcast cast(a,b), do: {:noreply, {:casted, a, b}}
 defcast cast(a,b,c), do: {:noreply, {:casted, a, b,c}}

 defcast private_cast(state), export: false, do: {:noreply, state}

 defcast named_cast(state), export: SampleServer, do: {:noreply, state}

 defcast custom_cast_export, export: [name: custom_cast_export_indeed], state: state, do: {:noreply, state}
 
 definfo info, do: {:noreply, :infoed}
 definfo info(a), do: {:noreply, {:infoed, a}}
 definfo info(a,b), do: {:noreply, {:infoed, a, b}}
 definfo info(a,b,c), do: {:noreply, {:infoed, a, b,c}}

 definfo private_info(state), export: false, do: {:noreply, state}

 definfo named_info(state), export: SampleServer, do: {:noreply, state}
 
 definfo custom_info_export, export: [name: custom_info_export_indeed], state: state, do: {:noreply, state}

 def init(_), do: {:ok, nil}
end

defmodule GenX.GenServer.Test do    
  alias GenX.GenServer.Sample, as: S
  alias :gen_server, as: GS
  use ExUnit.Case

  test "regular call with no arguments" do
    {:ok, pid} = GS.start_link(S,[],[])
    assert S.call(pid) == :call
  end

  test "regular call with one argument" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert (S.call(pid,1) == {:call, 1})
  end

  test "regular call with multiple arguments" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert (S.call(pid,1,2) == {:call, 1, 2})
      assert (S.call(pid,1,2,3) == {:call, 1, 2, 3})
  end

  test "regular call matching on state" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      S.set_state(pid, :hello)
      assert S.get_state(pid) == :hello
  end

  test "regular call matching on from" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert S.async_reply(pid) == :ok
  end

  test "private call" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert not :erlang.function_exported(S, :private_call, 1)
      assert not :erlang.function_exported(S, :private_call, 0)
      assert GS.call(pid, :private_call) == :ok
  end

  test "named call" do
      {:ok, _pid} = GS.start_link({:local, SampleServer},S, [],[]) 
      assert S.named_call == :ok
      Process.unregister SampleServer
  end

  test "custom timeout call" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert catch_exit(S.timeout(pid)) == {:timeout, {:gen_server, :call, [pid, :timeout, 1]}}
  end

  test "custom named timeout call" do
      {:ok, _pid} = GS.start_link({:local, SampleServer}, S,[],[]) 
      assert catch_exit(S.named_timeout) == {:timeout, {:gen_server, :call, [SampleServer, :named_timeout, 1]}}
      Process.unregister SampleServer
  end

  test "call custom export name" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert (S.custom_call_export_indeed(pid) == :custom)
  end

  test "regular cast with no arguments" do
    {:ok, pid} = GS.start_link(S,[],[])
    assert S.cast(pid) == :ok
    assert S.get_state(pid) == :casted
  end

  test "regular cast with one argument" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert S.cast(pid,1) == :ok
      assert S.get_state(pid) == {:casted, 1}
  end

  test "regular cast with multiple arguments" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert S.cast(pid,1,2) == :ok
      assert S.get_state(pid) == {:casted, 1, 2}
      assert S.cast(pid,1,2,3) == :ok
      assert S.get_state(pid) == {:casted, 1, 2, 3}
 end

  test "private cast" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert not :erlang.function_exported(S, :private_cast, 2)
      assert GS.cast(pid, {:private_cast, 123}) == :ok
      assert S.get_state(pid) == 123
  end

  test "named cast" do
      {:ok, pid} = GS.start_link({:local, SampleServer},S, [],[]) 
      assert S.named_cast(123) == :ok
      assert S.get_state(pid) == 123
      Process.unregister SampleServer
  end


  test "cast custom export name" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert (S.custom_cast_export_indeed(pid) == :ok)
  end


  test "regular info with no arguments" do
    {:ok, pid} = GS.start_link(S,[],[])
    assert S.info(pid) == :info
    assert S.get_state(pid) == :infoed
  end

  test "regular info with one argument" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert S.info(pid,1) == {:info, 1}
      assert S.get_state(pid) == {:infoed, 1}
  end

  test "regular info with multiple arguments" do
      {:ok, pid} = GS.start_link(S,[],[])
      assert S.info(pid,1,2) == {:info, 1, 2}
      assert S.get_state(pid) == {:infoed, 1, 2}
      assert S.info(pid,1,2,3) == {:info, 1, 2, 3}
      assert S.get_state(pid) == {:infoed, 1, 2, 3}
  end

  test "private info" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert not :erlang.function_exported(S, :private_info, 2)
      assert not :erlang.function_exported(S, :private_info, 1)
      assert (pid <- {:private_info, 123}) == {:private_info, 123}
      assert S.get_state(pid) == 123
  end

  test "named info" do
      {:ok, pid} = GS.start_link({:local, SampleServer},S, [],[]) 
      assert S.named_info(123) == {:named_info, 123}
      assert S.get_state(pid) == 123
      Process.unregister SampleServer
  end

  test "info custom export name" do
      {:ok, pid} = GS.start_link(S,[],[]) 
      assert (S.custom_info_export_indeed(pid) == :custom_info_export)
  end

end
