defmodule Exgettext.Helper do
  import IEx, only: [dont_display_result: 0]
  @doc """
  Prints the localized documentation for IEx.Helpers.
  if there is not localized document, prints original documentation.
  """
  def h() do
    Exgettext.Introspection.h(IEx.Helpers)
  end
  @h_modules [__MODULE__, IEx.Helpers, Kernel, Kernel.SpecialForms]

  @doc """
  Prints the localized documentation for the given module or 
  for the given function/arity pair.
  if there is not localized document, prints original documentation.
  """
  defmacro h(term) do
    quote do
      Exgettext.Introspection.h(unquote(IEx.Introspection.decompose(term, __CALLER__)))
    end
  end

end
