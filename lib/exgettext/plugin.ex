defmodule Exgettext.Plugin do
  @moduledoc """
  a translation plugin mechanism.

  """

  @doc """
  apply module, name, args like :erlang.apply/3.

  if fail or raise exception, invoke 'onerror/1' function
  (default fn(x) -> x.args end).
  onerror accepts a map 
   %{:error=>error, :module=> module, :name=>name,:args=> args}.

  Example:

    iex> Exgettext.Plugin.apply(BadModule, :add, [1,3])
    [1, 3]

  """
  def apply(module, name, args, onerror \\ fn(x) -> x.args end) do
    case Code.ensure_loaded(module) do
      {:module, ^module} ->
        try do
          Kernel.apply(module, name, args) 
        rescue
          x ->
            onerror.(%{:error=> x, :args=>args, :module=> module, 
                       :name=>name})
        end
      error ->
        onerror.(%{:error=> error, :args=>args, :module=> module, :name=>name})
    end
  end
end
