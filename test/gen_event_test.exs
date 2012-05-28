defmodule GenX.GenEvent.Sample do                                                           
 use GenEvent.Behavior                                                    
 import GenX.GenEvent                                                     

 def init(_), do: {:ok, nil}                                           

 defevent event, do: {:ok, :event}
 defevent event(a), do: {:ok, a}
 defevent event(a, b), do: {:ok, {a,b}}
 defevent event(a, b, c), do: {:ok, {a,b,c}}

 defevent private_event, export: false, do: {:ok, :private_event}
 defevent named_event, export: SampleEventManager, do: {:ok, :named_event}


 definfo info, do: {:ok, :info}
 definfo info(a), do: {:ok, a}
 definfo info(a, b), do: {:ok, {a,b}}
 definfo info(a, b, c), do: {:ok, {a,b,c}}

 definfo private_info, export: false, do: {:ok, :private_info}
 definfo named_info, export: SampleEventManager, do: {:ok, :named_info}



 defcall get_state, state: state, do: {:ok, state, state}

 # Suppress error logging
 def terminate(_, _), do: :ok
end


defmodule GenX.GenEvent.Test do    
  refer GenX.GenEvent.Sample, as: S
  refer :gen_event, as: GE
  use ExUnit.Case

  test "regular event call with no arguments" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      S.event(pid)
      assert S.get_state(pid) == :event
      GE.stop(pid)
  end

  test "regular event call with one argument" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      S.event(pid, 1)
      assert S.get_state(pid) == 1

      S.event(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.event(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

      GE.stop(pid)
  end

  test "regular event call with multiple arguments" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok

      S.event(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.event(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

      GE.stop(pid)
  end

  test "private event" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      assert not :erlang.function_exported(S, :private_event, 1)
      GE.notify(pid, :private_event)
      assert S.get_state(pid) == :private_event
      GE.stop(pid)
  end

  test "named event" do
      {:ok, _pid} = GE.start_link({:local, SampleEventManager}) 
      assert GE.add_handler(SampleEventManager, S, []) == :ok

      assert S.named_event == :ok
      assert S.get_state(SampleEventManager) == :named_event
      Process.unregister SampleEventManager
  end

  test "regular info call with no arguments" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      S.info(pid)
      assert S.get_state(pid) == :info
      GE.stop(pid)
  end

  test "regular info call with one argument" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      S.info(pid, 1)
      assert S.get_state(pid) == 1

      S.info(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.info(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

      GE.stop(pid)
  end

  test "regular info call with multiple arguments" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok

      S.info(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.info(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

      GE.stop(pid)
  end

  test "private info" do
      {:ok, pid} = GE.start_link
      assert GE.add_handler(pid, S, []) == :ok
      assert not :erlang.function_exported(S, :private_info, 1)
      pid <- :private_info
      assert S.get_state(pid) == :private_info
      GE.stop(pid)
  end

  test "named info" do
      {:ok, _pid} = GE.start_link({:local, SampleEventManager}) 
      assert GE.add_handler(SampleEventManager, S, []) == :ok

      assert S.named_info == :named_info
      assert S.get_state(SampleEventManager) == :named_info
      Process.unregister SampleEventManager
  end


end
