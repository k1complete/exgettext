defmodule Exgettext.Code do
  Exgettext.Util.defdelegate_filter(Exgettext.Code, Code,
                                        fn(x) -> not(x in [{:fetch_docs, 1}] )
                                     end)
  require Exgettext
  @doclang "en"
  defp doc_trans(app, docs, doclang) do
    Enum.map(docs, fn(x = {kna, anno, sig, doc, metadata}) ->
      case doc do
        doc when is_map(doc) ->
          if (rawdoc = Map.get(doc, doclang)) do
            {kna, 
             anno, 
             sig, 
             %{doclang => Exgettext.Runtime.gettext(app, rawdoc)},
             metadata}
          else
            x
          end
        :none -> x
        :hidden -> x
      end
    end)
  end
  @doc """
  Returns the localized docs for the given module.
  
  see `Elixir.Code.get_docs`
  """
  def fetch_docs(module) do
#    if (Exgettext.Helper === module) do
#      module = IEx.Helpers
#    end
    app = Exgettext.Util.get_app(module)
    case x = Elixir.Code.fetch_docs(module) do
      {:error, _reason} ->
        x
      {:docs_v1, anno, bleam_language, format, module_doc, metadata, docs} ->
        module_doc = %{@doclang => 
                        Exgettext.Runtime.gettext(app, module_doc[@doclang])}
        docs = doc_trans(app, docs, @doclang)
        {:docs_v1, anno, bleam_language, format, module_doc, metadata, docs}
      x ->
        x
    end
  end
end
#IO.inspect Exgettext.Code.__info__(:exports)
