defmodule Exgettext.Typespec do
  Exgettext.Util.defdelegate_filter(Exgettext.Typespec, Elixir.Kernel.Typespec,
                                    fn(x) -> 
                                      not(x in [{:beam_typedocs, 1}])
                                    end)
  @doclang "en"
  def beam_typedocs(module) do
    app = Exgettext.Util.get_app(module)
    {_, _, _, _, _, _, r} = Code.fetch_docs(module)
    Stream.filter(r, &(elem(elem(&1, 0), 0) == :type)) 
    |> Enum.map(fn({{:type, t, _}, _, _, d, _}) -> 
      rawdoc = Map.get(d, @doclang)
      ldoc = Exgettext.Runtime.gettext(app, rawdoc)
      {t, ldoc}
    end)
  end
end
