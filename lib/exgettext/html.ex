defmodule Exgettext.HTML do
  import Exgettext.Runtime, only: [gettext: 2]
  def run(module_nodes, config) when is_map(config) do
    m = module_nodes |> 
      Enum.map(fn(mod) ->
                 app = Exgettext.Util.get_app(mod.module)
                 Map.update(mod, :moduledoc, nil, 
                            fn(x) ->
                              s = gettext(app, x)
                              IO.puts s
                              s
                            end) |>
                 Map.update(:docs, nil, 
                            &(Enum.map(&1, 
                                       fn(x) -> 
                                         Map.update(x, :doc, nil,
                                                    fn(y) -> 
                                                      gettext(app, y)
                                                    end)
                                       end)))
               end)
    ExDoc.Formatter.HTML.run(m, config)
  end
end