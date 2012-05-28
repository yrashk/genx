defmodule Mix.Tasks.My do
   use Mix.Task
   @shortdoc "Test task"
   def run(_) do
       IO.inspect Mix.Tasks.Compile.__requires__
   end
end
defmodule Mix.Project do

   def project do
     [project: "GenX", version: "0.0.1", 
     compile_options: [ignore_module_conflict: true, docs: true]]
   end
   def application, do: []

end
