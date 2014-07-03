
defmodule Sample do
  @moduledoc """
  sample module for exgettext library
  """
  use Exgettext
  import Exgettext
  def hello() do
    IO.puts ~T"Hello, World"
  end

end
defmodule Sample2 do
  @moduledoc """
  sample module for exgettext library2
  """
  use Exgettext
  import Exgettext
  def hello() do
    IO.puts ~T"Hello, World"
  end

end
