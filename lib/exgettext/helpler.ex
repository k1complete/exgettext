defmodule Exgettext.Helper do
  import IEx, only: [dont_display_result: 0]
  def h() do
    Exgettext.Introspection.h(IEx.Helpers)
    dont_display_result
  end
  @h_modules [__MODULE__, IEx.Helpers, Kernel, Kernel.SpecialForms]

  defmacro h({:/, _, [call, arity]} = other) do
    args =
      case Macro.decompose_call(call) do
        {_mod, :__info__, []} when arity == 1 ->
          [Module, :__info__, 1]
        {mod, fun, []} ->
          [mod, fun, arity]
        {fun, []} ->
          [@h_modules, fun, arity]
        _ ->
          [other]
      end

    quote do
      Exgettext.Introspection.h(unquote_splicing(args))
    end
  end

  defmacro h(call) do
    args =
      case Macro.decompose_call(call) do
        {_mod, :__info__, []} ->
          [Module, :__info__, 1]
        {mod, fun, []} ->
          [mod, fun]
        {fun, []} ->
          [@h_modules, fun]
        _ ->
          [call]
      end

    quote do
      Exgettext.Introspection.h(unquote_splicing(args))
    end
  end

end
