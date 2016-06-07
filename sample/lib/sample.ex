
defmodule Sample do
  @moduledoc """
  sample module for exgettext library
  """
  use Exgettext
#  import Exgettext
  @doc """
  Hello is hello function
  """
  def hello() do
    IO.puts ~L"Hello, World"
  end

end
defmodule Sample2 do
  @moduledoc """
  sample module for exgettext library2
  """
  use Exgettext
  import Exgettext
  def hello() do
    IO.puts ~L"Hello, World2"
  end

end
