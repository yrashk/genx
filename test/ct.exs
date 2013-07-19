Code.require_file "test_helper.exs", __DIR__

defmodule MyTest do
  use CommonTest.Suite
  alias CommonTest, as: CT

  test "simple test" do
    1=1
  end

  test "simple test with a config", config: config do
    CT.pal("~p",[config])
    ^config=config
  end

  group "my group", :sequence do
    test "another test" do
      1=1
    end
  end

  group "another group", [:shuffle, :sequence] do
    test "interesting test" do
      1=1
    end
  end

end