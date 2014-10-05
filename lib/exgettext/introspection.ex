defmodule Exgettext.Introspection do
  import IEx, only: [dont_display_result: 0]

  def h(module) when is_atom(module) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        if function_exported?(module, :__info__, 1) do
          case Exgettext.Code.get_docs(module, :moduledoc) do
            {_, binary} when is_binary(binary) ->
              if opts = ansi_docs() do
                IO.ANSI.Docs.print_heading(inspect(module), opts)
                IO.ANSI.Docs.print(binary, opts)
              else
                IO.puts "* #{inspect(module)}\n"
                IO.puts binary
              end
            {_, _} ->
              nodocs(inspect module)
            _ ->
              IO.puts IEx.color(:eval_error, "#{inspect module} was not compiled with docs")
          end
        else
          IO.puts IEx.color(:eval_error, "#{inspect module} is an Erlang module and, as such, it does not have Elixir-style docs")
        end
      {:error, reason} ->
        IO.puts IEx.color(:eval_error, "Could not load module #{inspect module}, got: #{reason}")
    end
    dont_display_result
  end

  def h(_) do
    IO.puts IEx.color(:eval_error, "Invalid arguments for h helper")
    dont_display_result
  end

  @doc """
  Docs for the given function, with any arity, in any of the modules.
  """
  def h(modules, function) when is_list(modules) and is_atom(function) do
    result =
      Enum.reduce modules, :not_found, fn
        module, :not_found -> h_mod_fun(module, function)
        _module, acc -> acc
      end

    unless result == :ok, do:
      nodocs(function)

    dont_display_result
  end

  def h(module, function) when is_atom(module) and is_atom(function) do
    case h_mod_fun(module, function) do
      :ok ->
        :ok
      :no_docs ->
        IO.puts IEx.color(:eval_error, "#{inspect module} was not compiled with docs")
      :not_found ->
        nodocs("#{inspect module}.#{function}")
    end

    dont_display_result
  end

  defp h_mod_fun(mod, fun) when is_atom(mod) and is_atom(fun) do
    if docs = Exgettext.Code.get_docs(mod, :docs) do
      result = for {{f, arity}, _line, _type, _args, doc} <- docs, fun == f, doc != false do
        h(mod, fun, arity)
        IO.puts ""
      end

      if result != [], do: :ok, else: :not_found
    else
      :no_docs
    end
  end

  @doc """
  Documentation for the given function and arity in the list of modules.
  """
  def h(modules, function, arity) when is_list(modules) and is_atom(function) and is_integer(arity) do
    result =
      Enum.reduce modules, :not_found, fn
        module, :not_found -> h_mod_fun_arity(module, function, arity)
        _module, acc -> acc
      end

    unless result == :ok, do:
      nodocs("#{function}/#{arity}")

    dont_display_result
  end

  def h(module, function, arity) when is_atom(module) and is_atom(function) and is_integer(arity) do
    case h_mod_fun_arity(module, function, arity) do
      :ok ->
        :ok
      :no_docs ->
        IO.puts IEx.color(:eval_error, "#{inspect module} was not compiled with docs")
      :not_found ->
        nodocs("#{inspect module}.#{function}/#{arity}")
    end

    dont_display_result
  end

  defp h_mod_fun_arity(mod, fun, arity) when is_atom(mod) and is_atom(fun) and is_integer(arity) do
    if docs = Exgettext.Code.get_docs(mod, :docs) do
      doc =
        cond do
          d = find_doc(docs, fun, arity)         -> d
          d = find_default_doc(docs, fun, arity) -> d
          true                                   -> nil
        end

      if doc do
        print_doc(doc)
        :ok
      else
        :not_found
      end
    else
      :no_docs
    end
  end

  defp find_doc(docs, function, arity) do
    if doc = List.keyfind(docs, {function, arity}, 0) do
      case elem(doc, 4) do
        false -> nil
        _ -> doc
      end
    end
  end

  defp find_default_doc(docs, function, min) do
    Enum.find docs, fn(doc) ->
      case elem(doc, 0) do
        {^function, max} when max > min ->
          defaults = Enum.count elem(doc, 3), &match?({:\\, _, _}, &1)
          min + defaults >= max
        _ ->
          false
      end
    end
  end

  defp print_doc({{fun, _}, _line, kind, args, doc}) do
    args    = Enum.map_join(args, ", ", &print_doc_arg(&1))
    heading = "#{kind} #{fun}(#{args})"
    doc     = doc || ""

    if opts = ansi_docs() do
      IO.ANSI.Docs.print_heading(heading, opts)
      IO.ANSI.Docs.print(doc, opts)
    else
      IO.puts "* #{heading}\n"
      IO.puts doc
    end
  end

  defp print_doc_arg({:\\, _, [left, right]}) do
    print_doc_arg(left) <> " \\\\ " <> Macro.to_string(right)
  end

  defp print_doc_arg({var, _, _}) do
    Atom.to_string(var)
  end

  defp ansi_docs() do
    opts = Application.get_env(:iex, :colors)
    if color_enabled?(opts[:enabled]) do
      [width: IEx.width] ++ opts
    end
  end
  defp color_enabled?(nil), do: IO.ANSI.enabled?
  defp color_enabled?(bool) when is_boolean(bool), do: bool

  defp nodocs(for),  do: no(for, "documentation")

  defp no(for, type) do
    IO.puts IEx.color(:eval_error, "No #{type} for #{for} was found")
  end

  def conv_other(app, doc) do
    Exgettext.Runtime.gettext(app, doc)
  end
  def get_app(mod) do
#    :code.ensure_loaded(mod)
    {:file, r} = :code.is_loaded(mod)
    String.to_atom(Path.basename(Path.dirname(Path.dirname(r))))
  end
  def conv_doc(mod, {{func, arity}, line, type, args, doc}) do
    doc = conv_doc(mod, doc)
    {{func, arity}, line, type, args, doc}
  end
  def conv_doc(mod, doc) when is_binary(doc) do
    app = get_app(mod)
    conv_other(app, doc)
  end
end
