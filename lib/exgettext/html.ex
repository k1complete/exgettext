defmodule Exgettext.HTML do
  import Exgettext.Runtime, only: [gettext: 2]
  alias ExDoc.Formatter.HTML.Templates
  alias ExDoc.Formatter.HTML.Autolink

  def run(module_nodes, config) when is_map(config) do
    m = module_nodes |> 
      Enum.map(fn(mod) ->
                 app = Exgettext.Util.get_app(mod.module)
                 Map.update(mod, :moduledoc, nil, 
                            fn(x) ->
                              s = gettext(app, x)
#                              IO.inspect [app: app, doc: s]
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
    all = Autolink.all(m)
    modules    = filter_list(:modules, all)
    exceptions = filter_list(:exceptions, all)
    protocols  = filter_list(:protocols, all)
    output  = config.output
    extras = generate_extras(output, m, modules, exceptions, protocols, config)
    extra_config = %{config| extras: extras}
    ExDoc.Formatter.HTML.run(m, extra_config)
  end
  def generate_extras(output, m, modules, exceptions, protocols, config) do
    extras =
      config.extras
      |> Enum.map(&Task.async(fn ->
          generate_extra(&1, output, m, modules, exceptions, protocols, config)
         end))
      |> Enum.map(&Task.await(&1, :infinity))
    [{"api-reference", "API Reference", []}|extras]
  end
  defp generate_extra({input_file, options}, output, module_nodes, modules, exceptions, protocols, config) do
    input_file = to_string(input_file)
    output_file_name = Path.join(options[:path], input_file)

    options = %{
      title: options[:title],
      output_file_name: output_file_name,
      input: input_file,
      output: output
    }

  end
  defp generate_extra(input, output, module_nodes, modules, exceptions, protocols, config) do
    output_file_name = input |> input_to_title |> title_to_filename

    options = %{
      output_file_name: output_file_name,
      input: input,
      output: output
    }

#    create_extra_files(module_nodes, modules, exceptions, protocols, config, options)
  end

  defp filter_list(:modules, nodes) do
    Enum.filter nodes, &(not &1.type in [:exception, :protocol, :impl])
  end
  defp filter_list(:exceptions, nodes) do
    Enum.filter nodes, &(&1.type in [:exception])
  end
  defp filter_list(:protocols, nodes) do
    Enum.filter nodes, &(&1.type in [:protocol])
  end
  defp input_to_title(input) do
    input |> Path.basename() |> Path.rootname()
  end
  defp title_to_filename(title) do
    title |> String.replace(" ", "-") |> String.downcase()
  end
  defp extract_title(content) do
    title = Regex.run(~r/^#([^#].*)\n$/m, content, capture: :all_but_first)
    if title do
      title |> List.first |> String.strip
    end
  end
  defp link_headers(content) do
    Regex.replace(~r/##([^#].*)\n$/m, content, fn _, part ->
                  "<h2 id=#{inspect header_to_id(part)}>#{part}</h2>"
                  end)
  end
  defp header_to_id(header) do
    header
    |> String.strip()
    |> String.replace(~r/\W+/, "-")
  end
end