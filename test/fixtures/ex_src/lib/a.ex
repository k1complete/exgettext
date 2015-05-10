
defmodule A do
  use Exgettext
  @moduledoc """
  module doc for A
  """

  @doc """
  method doc for hello
  """
  def hello do
    ~T"Hello world"
  end
  def hello2 do
    setlocale("en")
    ~T"Hello world"
  end
  def helloja do
    ja = "ja"
    ~T"Hello world"ja
  end
end