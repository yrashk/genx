defmodule Application.Test do
  use ExUnit.Case

  def cleanup do
    :error_logger.delete_report_handler(:error_logger_tty_h)
    Application.stop(:crypto)
    Application.stop(:public_key)
    Application.stop(:ssl)
    :error_logger.add_report_handler(:error_logger_tty_h)
  end
    
  test "starting application without dependencies" do
    cleanup
    assert Application.start(:ssl, dependencies: false) == {:error, {:not_started, :crypto}}
    cleanup
  end

  test "starting application with dependencies" do
    cleanup
    assert Application.start(:ssl, dependencies: true) == :ok
    cleanup
  end

  test "starting application with dependencies (by default)" do
    cleanup
    assert Application.start(:ssl) == :ok
    cleanup
  end

end