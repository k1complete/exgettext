defmodule Exgettext.Introspection do
  import IEx, only: [dont_display_result: 0]
  alias Code.Typespec
  @doc """
  Decomposes an introspection call into `{mod, fun, arity}`,
  `{mod, fun}` or `mod`.
  """
  def decompose({:/, _, [call, arity]} = term, context) do
    case Macro.decompose_call(call) do
      {_mod, :__info__, []} when arity == 1 ->
        {:{}, [], [Module, :__info__, 1]}

      {mod, fun, []} ->
        {:{}, [], [mod, fun, arity]}

      {fun, []} ->
        {:{}, [], [find_decompose_fun_arity(fun, arity, context), fun, arity]}

      _ ->
        term
    end
  end

  def decompose(call, context) do
    case Macro.decompose_call(call) do
      {_mod, :__info__, []} ->
        Macro.escape({Module, :__info__, 1})

      {mod, fun, []} ->
        {mod, fun}

      {fun, []} ->
        {find_decompose_fun(fun, context), fun}

      _ ->
        call
    end
  end

  defp find_decompose_fun(fun, context) do
    find_import(fun, context.functions) || find_import(fun, context.macros) ||
      find_special_form(fun) || Kernel
  end

  defp find_decompose_fun_arity(fun, arity, context) do
    pair = {fun, arity}

    find_import(pair, context.functions) || find_import(pair, context.macros) ||
      find_special_form(pair) || Kernel
  end

  defp find_import(pair, context) when is_tuple(pair) do
    Enum.find_value(context, fn {mod, functions} ->
      if pair in functions, do: mod
    end)
  end

  defp find_import(fun, context) do
    Enum.find_value(context, fn {mod, functions} ->
      if Keyword.has_key?(functions, fun), do: mod
    end)
  end
  defp find_special_form(pair) when is_tuple(pair) do
    special_form_function? = pair in Kernel.SpecialForms.__info__(:functions)
    special_form_macro? = pair in Kernel.SpecialForms.__info__(:macros)

    if special_form_function? or special_form_macro?, do: Kernel.SpecialForms
  end

  defp find_special_form(fun) do
    special_form_function? = Keyword.has_key?(Kernel.SpecialForms.__info__(:functions), fun)
    special_form_macro? = Keyword.has_key?(Kernel.SpecialForms.__info__(:macros), fun)

    if special_form_function? or special_form_macro?, do: Kernel.SpecialForms
  end


  @doc """
  Prints documentation.
  """
  def h(module) when is_atom(module) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        case Code.fetch_docs(module) do
          {:docs_v1, _, _, _, %{} = doc, metadata, _} ->
            print_doc(inspect(module), [], doc, metadata)

          {:docs_v1, _, _, _, _, _, _} ->
            docs_not_found(inspect(module))

          _ ->
            no_docs(module)
        end

      {:error, reason} ->
        puts_error("Could not load module #{inspect(module)}, got: #{reason}")
    end

    dont_display_result()
  end

  def h({module, function}) when is_atom(module) and is_atom(function) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        docs = get_docs(module, [:function, :macro])

        exports =
          cond do
            docs ->
              Enum.map(docs, &extract_name_and_arity/1)

            function_exported?(module, :__info__, 1) ->
              module.__info__(:functions) ++ module.__info__(:macros)

            true ->
              module.module_info(:exports)
          end
          |> Enum.sort()

        result =
          for {^function, arity} <- exports,
              (if docs do
                 find_doc_with_content(docs, function, arity)
               else
                 get_spec(module, function, arity) != []
               end) do
            h_mod_fun_arity(module, function, arity)
          end

        cond do
          result != [] ->
            :ok

          docs && has_callback?(module, function) ->
            behaviour_found("#{inspect(module)}.#{function}")

          docs && has_type?(module, function) ->
            type_found("#{inspect(module)}.#{function}")

          is_nil(docs) ->
            no_docs(module)

          true ->
            docs_not_found("#{inspect(module)}.#{function}")
        end

      {:error, reason} ->
        puts_error("Could not load module #{inspect(module)}, got: #{reason}")
    end

    dont_display_result()
  end

  def h({module, function, arity})
      when is_atom(module) and is_atom(function) and is_integer(arity) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        case h_mod_fun_arity(module, function, arity) do
          :ok ->
            :ok

          :behaviour_found ->
            behaviour_found("#{inspect(module)}.#{function}/#{arity}")

          :type_found ->
            type_found("#{inspect(module)}.#{function}/#{arity}")

          :no_docs ->
            no_docs(module)

          :not_found ->
            docs_not_found("#{inspect(module)}.#{function}/#{arity}")
        end

      {:error, reason} ->
        puts_error("Could not load module #{inspect(module)}, got: #{reason}")
    end

    dont_display_result()
  end

  def h(invalid) do
    puts_error(
      "The \"h\" helper expects a Module, Module.fun or Module.fun/arity, got: #{inspect(invalid)}"
    )

    puts_error(
      "If instead of accessing documentation you would like more information about a value " <>
        "or about the result of an expression, use the \"i\" helper instead"
    )

    dont_display_result()
  end

  defp h_mod_fun_arity(mod, fun, arity) when is_atom(mod) do
    docs = get_docs(mod, [:function, :macro])
    spec = get_spec(mod, fun, arity)

    cond do
      doc_tuple = find_doc_with_content(docs, fun, arity) ->
        print_fun(mod, doc_tuple, spec)
        :ok

      docs && has_callback?(mod, fun, arity) ->
        :behaviour_found

      docs && has_type?(mod, fun, arity) ->
        :type_found

      is_nil(docs) and spec != [] ->
        message = %{"en" => "Module was compiled without docs. Showing only specs."}
        print_doc("#{inspect(mod)}.#{fun}/#{arity}", spec, message, %{})
        :ok

      is_nil(docs) ->
        :no_docs

      true ->
        :not_found
    end
  end
  defp behaviour_found(for) do
    puts_error("""
    No documentation for function #{for} was found, but there is a callback with the same name.
    You can view callback documentation with the b/1 helper.
    """)
  end

  defp type_found(for) do
    puts_error("""
    No documentation for function #{for} was found, but there is a type with the same name.
    You can view type documentation with the t/1 helper.
    """)
  end
  defp not_found(for, type) do
    puts_error("No #{type} for #{for} was found")
  end

  defp no_docs(module) do
    puts_error("#{inspect(module)} was not compiled with docs")
  end
  defp types_not_found(for), do: not_found(for, "type information")
  defp docs_not_found(for), do: not_found(for, "documentation")
  defp types_not_found_or_private(for) do
    puts_error("No type information for #{for} was found or #{for} is private")
  end


  defp get_docs(mod, kinds) do
    case Exgettext.Code.fetch_docs(mod) do
      {:docs_v1, _, _, _, _, _, docs} ->
        for {{kind, _, _}, _, _, _, _} = doc <- docs, kind in kinds, do: doc

      {:error, _} ->
        nil
    end
  end
  defp extract_name_and_arity({{_, name, arity}, _, _, _, _}), do: {name, arity}
  defp find_doc_with_content(docs, function, arity) do
    doc = find_doc(docs, function, arity)
    if doc != nil and has_content?(doc), do: doc
  end
  defp has_content?({_, _, _, :hidden, _}), do: false
  defp has_content?({{_, name, _}, _, _, :none, _}), do: hd(Atom.to_charlist(name)) != ?_
  defp has_content?({_, _, _, _, _}), do: true

  defp find_doc(nil, _fun, _arity) do
    nil
  end

  defp find_doc(docs, fun, arity) do
    Enum.find(docs, &match?({_, ^fun, ^arity}, elem(&1, 0))) ||
      find_doc_defaults(docs, fun, arity)
  end

  defp find_doc_defaults(docs, function, min) do
    Enum.find(docs, fn
      {{_, ^function, arity}, _, _, _, %{defaults: defaults}} when arity > min ->
        arity <= min + defaults

      _ ->
        false
    end)
  end

  defp has_callback?(mod, fun) do
    case get_callback_docs(mod, &match?({_, ^fun, _}, elem(&1, 0))) do
      {:ok, [_ | _]} -> true
      _ -> false
    end
  end

  defp has_callback?(mod, fun, arity) do
    case get_callback_docs(mod, &match?({_, ^fun, ^arity}, elem(&1, 0))) do
      {:ok, [_ | _]} -> true
      _ -> false
    end
  end

  defp has_type?(mod, fun) do
    mod
    |> get_docs([:type])
    |> Enum.any?(&match?({_, ^fun, _}, elem(&1, 0)))
  end

  defp has_type?(mod, fun, arity) do
    mod
    |> get_docs([:type])
    |> Enum.any?(&match?({_, ^fun, ^arity}, elem(&1, 0)))
  end

  defp callback_module(mod, fun, arity) do
    mod.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> Stream.concat()
    |> Enum.find(&has_callback?(&1, fun, arity))
  end

  defp get_spec(module, name, arity) do
    with {:ok, all_specs} <- Typespec.fetch_specs(module),
         {_, specs} <- List.keyfind(all_specs, {name, arity}, 0) do
      formatted =
        Enum.map(specs, fn spec ->
          Typespec.spec_to_quoted(name, spec)
          |> format_typespec(:spec, 2)
        end)

      [formatted, ?\n]
    else
      _ -> []
    end
  end

  defp get_callback_docs(mod, filter) do
    docs = get_docs(mod, [:callback, :macrocallback])

    case Typespec.fetch_callbacks(mod) do
      :error ->
        :no_beam

      {:ok, callbacks} ->
        docs =
          callbacks
          |> Enum.map(&translate_callback/1)
          |> Enum.filter(filter)
          |> Enum.sort()
          |> Enum.flat_map(fn {{_, function, arity}, _specs} = callback ->
            case find_doc(docs, function, arity) do
              nil -> [{format_callback(callback), :none, %{}}]
              {_, _, _, :hidden, _} -> []
              {_, _, _, doc, metadata} -> [{format_callback(callback), doc, metadata}]
            end
          end)

        {:ok, docs}
    end
  end
  defp translate_callback({name_arity, specs}) do
    case translate_callback_name_arity(name_arity) do
      {:macrocallback, _, _} = kind_name_arity ->
        # The typespec of a macrocallback differs from the one expressed
        # via @macrocallback:
        #
        #   * The function name is prefixed with "MACRO-"
        #   * The arguments contain an additional first argument: the caller
        #   * The arity is increased by 1
        #
        specs =
          Enum.map(specs, fn {:type, line1, :fun, [{:type, line2, :product, [_ | args]}, spec]} ->
            {:type, line1, :fun, [{:type, line2, :product, args}, spec]}
          end)

        {kind_name_arity, specs}

      kind_name_arity ->
        {kind_name_arity, specs}
    end
  end

  defp translate_callback_name_arity({name, arity}) do
    case Atom.to_string(name) do
      "MACRO-" <> macro_name -> {:macrocallback, String.to_atom(macro_name), arity - 1}
      _ -> {:callback, name, arity}
    end
  end

  defp format_callback({{kind, name, _arity}, specs}) do
    Enum.map(specs, fn spec ->
      Typespec.spec_to_quoted(name, spec)
      |> Macro.prewalk(&drop_macro_env/1)
      |> format_typespec(kind, 0)
    end)
  end

  defp drop_macro_env({name, meta, [{:"::", _, [_, {{:., _, [Macro.Env, :t]}, _, _}]} | args]}),
    do: {name, meta, args}

  defp drop_macro_env(other), do: other
  defp print_typespec({types, doc, metadata}) do
    IO.puts(types)
    doc = translate_doc(doc)

    if opts = IEx.Config.ansi_docs() do
      IO.ANSI.Docs.print_metadata(metadata, opts)
      doc && IO.ANSI.Docs.print(doc, opts)
    else
      IO.ANSI.Docs.print_metadata(metadata, enabled: false)
      doc && IO.puts(doc)
    end
  end

  defp translate_doc(:none), do: nil
  defp translate_doc(:hidden), do: nil
  defp translate_doc(%{"en" => doc}) do
    doc
  end
  defp format_typespec(definition, kind, nesting) do
    "@#{kind} #{Macro.to_string(definition)}"
    |> Code.format_string!(line_length: IEx.width() - 2 * nesting)
    |> IO.iodata_to_binary()
    |> color_prefix_with_line()
    |> indent(nesting)
  end

  defp indent(content, 0) do
    [content, ?\n]
  end

  defp indent(content, nesting) do
    whitespace = String.duplicate(" ", nesting)
    [whitespace, String.replace(content, "\n", "\n#{whitespace}"), ?\n]
  end

  defp color_prefix_with_line(string) do
    [left, right] = :binary.split(string, " ")
    IEx.color(:doc_inline_code, left) <> " " <> right
  end


  defp print_doc(heading, types, doc, metadata) do
    doc = translate_doc(doc) || ""

    if opts = IEx.Config.ansi_docs() do
      IO.ANSI.Docs.print_heading(heading, opts)
      IO.write(types)
      IO.ANSI.Docs.print_metadata(metadata, opts)
      IO.ANSI.Docs.print(doc, opts)
    else
      IO.puts("* #{heading}\n")
      IO.write(types)
      IO.ANSI.Docs.print_metadata(metadata, enabled: false)
      IO.puts(doc)
    end
  end
  defp print_fun(mod, {{kind, fun, arity}, _line, signature, doc, metadata}, spec) do
    if callback_module = doc == :none and callback_module(mod, fun, arity) do
      filter = &match?({_, ^fun, ^arity}, elem(&1, 0))

      case get_callback_docs(callback_module, filter) do
        {:ok, callback_docs} -> Enum.each(callback_docs, &print_typespec/1)
        _ -> nil
      end
    else
      print_doc("#{kind_to_def(kind)} #{Enum.join(signature, " ")}", spec, doc, metadata)
    end
  end

  defp kind_to_def(:function), do: :def
  defp kind_to_def(:macro), do: :defmacro

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
  defp puts_error(string) do
    IO.puts(IEx.color(:eval_error, string))
  end
end
