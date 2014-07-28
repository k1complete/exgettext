
defmodule A do
  use Exgettext
#  import Exgettext
  @moduledoc """
  module doc for A
  """

  @doc """
  method doc for hello
  """
  def hello do
    ~T"Hello world"
  end
end