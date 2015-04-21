defmodule Exgettext.Kernel.Typespec do
  Exgettext.Util.defdelegate_filter(Exgettext.Kernel.Typespec, Kernel.Typespec,
                                    fn(x) -> 
                                      not(x in [{:beam_typedocs, 1}])
                                    end)
  def beam_typedocs(module) do
    app = Exgettext.Util.get_app(module)
    r = Elixir.Kernel.Typespec.beam_typedocs(module)
    Enum.map(r, fn(x) ->
                  d = elem(x, 1)
                  dloc = Exgettext.Runtime.gettext(app, d)
                  IO.inspect [dloc: dloc]
                  put_elem(x, 1, dloc)
             end)
  end
end