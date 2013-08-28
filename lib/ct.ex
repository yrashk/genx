defmodule CommonTest do

  def pal(s), do: :ct.pal(to_char_list(s))
  def pal(fmt, data), do: :ct.pal(to_char_list(fmt), data)
  def pal(category, fmt, data), do: :ct.pal(category, to_char_list(fmt), data)

  def run(options) do
    :ct.run_test(Keyword.put options, :auto_compile, false)
  end

  def run(path, options) when is_binary(path), do: run([path], options)
  def run(paths, options) do
    files = scan(paths)
    run(files, options, [])
  end

  defp run([], _options, acc), do: acc
  defp run([file_path|rest], options, acc) do
    res = test_file(file_path, options)
    run(rest, options, res ++ acc)
  end

  def test_file(file_path, options) do
    suites = lc mod inlist extract_modules(file_path), is_test?(mod), do: mod
    case suites do
      [] -> []
      suites ->
        options = Keyword.merge options, [suite: suites]
        [run(options)]
    end
  end

  def scan(paths) do
    files =
      Enum.concat(
        lc path inlist paths do
          if File.regular?(path) do
            [path]
          else
            Path.wildcard("#{path}/**/*.exs")
          end
      end)
    files |> filter |> Enum.uniq
  end

  def filter(files) do
    Enum.filter(files, fn(x) -> String.first(Path.basename(x)) != "." end)
  end

  def extract_modules(file_path) do
    lc {m, _} inlist :elixir_compiler.file(file_path), do: m
  end

  def is_test?(module) do
    Keyword.has_key?(module.__info__(:attributes), :common_test)
  end
end

defmodule CommonTest.Suite do
  defmacro __using__(_) do
    quote do
      import CommonTest.Suite
      Module.register_attribute unquote(__CALLER__.module), :common_test
      @common_test true

      def suite, do: []

      def init_per_suite(config) do
        try do
          __init__(config)
        rescue FunctionClauseError ->
          config
        end
      end

      def end_per_suite(config) do
        try do
          __end__(config)
        rescue FunctionClauseError ->
          config
        end
      end

      def __init__(config), do: config
      def __end__(_config), do: :ok

      def init_per_group(name, config) do
        try do
          __init_group__(name, config)
        rescue FunctionClauseError ->
          config
        end
      end

      def end_per_group(name, config) do
        try do
          __end_group__(name, config)
        rescue FunctionClauseError ->
          config
        end
      end

      def __init_group__(_name, config), do: config
      def __end_group__(_name, _config), do: :ok

      def init_per_testcase(name, config) do
        try do
          __init_testcase__(name, config)
        rescue FunctionClauseError ->
          config
        end
      end

      def end_per_testcase(name, config) do
        try do
          __end_testcase__(name, config)
        rescue FunctionClauseError ->
          config
        end
      end

      def __init_testcase__(_name, config), do: config
      def __end_testcase__(_name, _config), do: :ok


      Module.register_attribute unquote(__CALLER__.module), :all,
                                persist: true, accumulate: true

      Module.register_attribute unquote(__CALLER__.module), :groups,
                                persist: true, accumulate: true

      Module.register_attribute unquote(__CALLER__.module), :group,
                                persist: false, accumulate: false

      Module.register_attribute unquote(__CALLER__.module), :group_test,
                                persist: false, accumulate: true

      def all do
        lc {:all, [test]} inlist module_info(:attributes), do: test
      end

      def groups do
        lc {:groups, [group]} inlist module_info(:attributes), do: group
      end

      defoverridable [suite: 0, __init__: 1, __end__: 1, __init_group__: 2, __end_group__: 2, __init_testcase__: 2, __end_testcase__: 2]
    end
  end

  defmacro test(test_name, options, [do: block]) do
    _test(test_name, Keyword.put(options, :do, block), __CALLER__)
  end
  defmacro test(test_name, [do: block]) do
    _test(test_name, [do: block], __CALLER__)
  end

  defp _test(name, options, caller) do
    name = name_to_atom(name)
    cfg = options[:config] || {:_, [], :quoted}
    info = Keyword.delete(Keyword.delete(options, :config), :do)
    quote do
      if Module.get_attribute(unquote(caller.module), :group) == nil do
        @all unquote(name)
      else
        @group_test unquote(name)
      end
      def unquote(name).(unquote(cfg)) do
        unquote(options[:do])
      end
      if unquote(info) != [] do
       def unquote(name).(), do: unquote(info)
      end
    end
  end


  defmacro group(name, type, [do: block]) do
    unless is_list(type), do: type = [type]
    name = name_to_atom(name)
    quote do
      Module.delete_attribute unquote(__CALLER__.module), :group_test
      @group {unquote(name), unquote(type)}
      unquote(block)
      @group nil
      @groups {unquote(name), unquote(type), Module.get_attribute(unquote(__CALLER__.module), :group_test)}
     @all {:group, unquote(name)}
    end
  end



  defp name_to_atom(atom) when is_atom(atom), do: atom
  defp name_to_atom(string) when is_binary(string), do: binary_to_atom(string)
  defp name_to_atom(string) when is_list(string), do: list_to_atom(string)


end