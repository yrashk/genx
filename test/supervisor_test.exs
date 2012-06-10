defmodule GenX.Supervisor.Sample do
  alias GenX.Supervisor, as: Sup

  def start_link do
      tree = Sup.OneForOne.new(id: OFO,
                               children: [
                                  Sup.OneForOne.new(id: OFO.Registered, registered: OFO.Registered,
                                                    children: [])
                               ])
      Sup.start_link tree
  end

end

defmodule GenX.Supervisor.Test do
   use ExUnit.Case
   alias GenX.Supervisor.Sample, as: S

   test "start" do
       {:ok, pid} = S.start_link
       [{OFO.Registered, pid_ofor, :supervisor, _}] = :supervisor.which_children(pid)
       assert :supervisor.which_children(pid_ofor) == []
       assert Process.whereis(OFO.Registered) == pid_ofor
   end
end