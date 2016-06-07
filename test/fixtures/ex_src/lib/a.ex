
defmodule A do
  use Exgettext
  @moduledoc """
  module doc for A
  """

  @doc """
  method doc for hello
  """
  def hello do
    ~L"Hello world"
  end
  def hello2 do
    setlocale("en")
    ~L"Hello world"
  end
  def helloja do
    ja = "ja"
    ~L"Hello world"ja
  end
end
