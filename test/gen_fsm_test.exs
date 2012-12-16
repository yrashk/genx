defmodule GenX.GenFsm.Sample do
 use GenFsm.Behaviour
 import GenX.GenFsm

 def init(_), do: {:ok, :testing, nil}

 defevent testing/event, do: {:next_state, :testing, :event}
 defevent testing/event(a), do: {:next_state, :testing, a}
 defevent testing/event(a,b), do: {:next_state, :testing, {a,b}}
 defevent testing/event(a,b,c), do: {:next_state, :testing, {a,b,c}}

 defevent testing/private_event, export: false, do: {:next_state, :testing, :private_event}

 defevent testing/named_event, export: SampleFSM, do: {:next_state, :testing, :named_event}

 defevent testing/sync_event, sync: true, do: {:reply, :sync_event, :testing, :sync_event}

 defevent testing/sync_all_states_event, sync: true, all_states: true, do: {:reply, :sync_all_states_event, :testing, :sync_all_states_event}

 defevent testing/all_states_event, all_states: true, do: {:next_state, :testing, :all_states_event}

 defevent testing/timeout, sync: true, export: [timeout: 2] do
    :timer.sleep(4)
    {:next_state, :testing, :timeout}
 end

 defevent testing/named_timeout, sync: true, export: [server: SampleFSM, timeout: 2] do
    :timer.sleep(4)
    {:next_state, :testing, :named_timeout}
 end

 definfo info, state_name: state_name, do: {:next_state, state_name, :info}
 definfo info(a), state_name: state_name, do: {:next_state, state_name, a}
 definfo info(a, b), state_name: state_name, do: {:next_state, state_name, {a,b}}
 definfo info(a, b, c), state_name: state_name, do: {:next_state, state_name, {a,b,c}}

 definfo private_info, state_name: state_name, export: false, do: {:next_state, state_name, :private_info}
 definfo named_info, state_name: state_name, export: SampleFSM, do: {:next_state, state_name, :named_info}

 defevent get_state, state_name: state_name, state: state,
                     all_states: true, sync: true do
    {:reply, state, state_name, state} 
 end

 # Suppress error logging
 def terminate(_, _), do: :ok
end


defmodule GenX.GenFsm.Test do    
  alias GenX.GenFsm.Sample, as: S
  alias :gen_fsm, as: FSM
  use ExUnit.Case

  test "regular event with no arguments" do
      {:ok, pid} = FSM.start_link S, [], []
      S.event(pid)
      assert S.get_state(pid) == :event
  end

  test "regular event with one argument" do
      {:ok, pid} = FSM.start_link S, [], []
      S.event(pid, 1)
      assert S.get_state(pid) == 1
  end


  test "regular event with multiple arguments" do
      {:ok, pid} = FSM.start_link S, [], []
      S.event(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.event(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

  end

  test "private event" do
      {:ok, pid} = FSM.start_link S, [], []

      assert not :erlang.function_exported(S, :private_event, 1)
      FSM.send_event pid, :private_event

      assert S.get_state(pid) == :private_event
  end

  test "named event" do
      {:ok, _pid} = FSM.start_link({:local, SampleFSM}, S, [], []) 

      assert S.named_event == :ok
      assert S.get_state(SampleFSM) == :named_event
      Process.unregister SampleFSM
  end

  test "sync event" do
      {:ok, pid} = FSM.start_link S, [], []
      assert S.sync_event(pid) == :sync_event
  end

  test "sync + all states event" do
      {:ok, pid} = FSM.start_link S, [], []
      assert S.sync_all_states_event(pid) == :sync_all_states_event
  end

  test "all states event" do
      {:ok, pid} = FSM.start_link S, [], []
      S.all_states_event(pid)
      assert S.get_state(pid) == :all_states_event
  end


  test "regular info call with no arguments" do
      {:ok, pid} = FSM.start_link S, [], []
      S.info(pid)
      assert S.get_state(pid) == :info
  end

  test "regular info call with one argument" do
      {:ok, pid} = FSM.start_link S, [], []

      S.info(pid, 1)
      assert S.get_state(pid) == 1

      S.info(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.info(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}
  end

  test "regular info call with multiple arguments" do
      {:ok, pid} = FSM.start_link S, [], []

      S.info(pid, 1, 2)
      assert S.get_state(pid) == {1,2}

      S.info(pid, 1, 2, 3)
      assert S.get_state(pid) == {1,2,3}

  end

  test "private info" do
      {:ok, pid} = FSM.start_link S, [], []
      assert not :erlang.function_exported(S, :private_info, 1)
      pid <- :private_info
      assert S.get_state(pid) == :private_info
  end

  test "named info" do
      {:ok, _pid} = FSM.start_link {:local, SampleFSM}, S, [], []

      assert S.named_info == :named_info
      assert S.get_state(SampleFSM) == :named_info
      Process.unregister SampleFSM
  end

  test "custom timeout call" do
      {:ok, pid} = FSM.start_link S, [], []
      assert catch_exit(S.timeout(pid)) == {:timeout, {:gen_fsm, :sync_send_event, [pid, :timeout, 2]}}
  end

  test "custom named timeout call" do
      {:ok, _pid} = FSM.start_link {:local, SampleFSM}, S, [], []
      assert catch_exit(S.named_timeout) == {:timeout, {:gen_fsm, :sync_send_event, [SampleFSM, :named_timeout, 2]}}
      Process.unregister SampleFSM
  end


end
