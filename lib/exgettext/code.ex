defmodule Exgettext.Code do
  Exgettext.Util.defdelegate_filter(Exgettext.Code, Code,
                                        fn(x) -> not(x in [{:get_docs, 2}] )
                                     end)
  defp get_docs_func(_app, nil) do
    nil
  end
  defp get_docs_func(app, r) do
    Enum.map(r, fn(x) -> 
                  d = elem(x, 4)
                  dloc = Exgettext.Runtime.gettext(app, d)
                  put_elem(x, 4, dloc)
             end)
  end
  defp get_docs_mod(_app, nil) do
    nil
  end
  defp get_docs_mod(app, r) do
    d = elem(r, 1)
    dloc = Exgettext.Runtime.gettext(app, d)
    put_elem(r, 1, dloc)
  end
  defp get_docs_type(app, r) do
    Enum.map(r, fn(x) ->
                  d = elem(x, 3)
                  dloc = Exgettext.Runtime.gettext(app, d)
                  put_elem(x, 4, dloc)
             end)
  end
  @doc """
  Returns the localized docs for the given module.
  
  see `Elixir.Code.get_docs`
  """
  def get_docs(module, kind) do
#    if (Exgettext.Helper === module) do
#      module = IEx.Helpers
#    end
    app = Exgettext.Util.get_app(module)
    r = Elixir.Code.get_docs(module, kind)
    case kind do
      :docs ->
        get_docs_func(app, r)
      :moduledoc ->
        get_docs_mod(app, r)
      _ ->
        [docs: docs, moduledoc: moduledoc, 
         callback_docs: callback_docs,
         type_docs: type_docs
        ] = r
        [docs: get_docs_func(app, docs),
         moduledoc: get_docs_mod(app, moduledoc),
         callback_docs: get_docs_func(app, callback_docs),
         type_docs: get_docs_type(app, type_docs)
        ]
    end
  end
end
#IO.inspect Exgettext.Code.__info__(:exports)