defmodule PapaTest do
  use ExUnit.Case
  doctest Papa

  test "greets the world" do
    assert Papa.hello() == :world
  end
end
