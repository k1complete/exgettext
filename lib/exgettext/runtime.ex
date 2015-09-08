defmodule Exgettext.Runtime do
  def basedir(app) do
    case :code.priv_dir(app) do
      {:error, _other} -> 
        Logger.warning(ArgumentError, message: "bad app #{app}, cannot find to app path")
        "priv"
      r -> r
    end
  end
  def mofile(app, lang) do
    Path.join([basedir(app), "lang", "#{lang}", "#{app}.exmo"])
  end
  def getpath(app, lang) do
    mofile(app, lang)
  end
  defp locale_to_lang("C") do
    "en"
  end
  defp locale_to_lang(nil) do
    "en"
  end
  defp locale_to_lang(locale) do
    case Regex.run(~r/([^._]+)_([^._]+)\.([^.])+/, locale) do
      nil -> locale
      [^locale, lang, _country, _encoding] -> 
        lang
    end
  end
  def getlang(lang) do
    locale_to_lang(lang)
  end
  defp getlang() do
    case Exgettext.getlocale() do
      nil -> 
        getlang(System.get_env("LANG"))
      r -> 
        r
    end
  end
  def gettext(app, key, lang) do
#    IO.inspect [gettext: app, key: key]
    r = case gettext_raw(app, key, lang) do
          {:ok, r} -> r
          _ ->
            rm = try do
                       gettext_raw(:"l10n_#{app}", key, lang)
                     rescue 
                       _x -> 
                         {:error, key}
                     end
            {_, r} = rm
            r
        end
    r
  end
  def gettext_raw(_app, nil, _lang) do
    {:ok, nil}
  end
  def gettext_raw(app, key, lang) do
    dets_file = getpath(app, lang)
    #IO.inspect [gettext_raw: app, dets: dets_file]
    case :dets.open_file(dets_file) do
      {:ok, dets} ->
        r = case :dets.lookup(dets, key) do
              [] -> key
              [{^key, ""}] -> key
              [{^key, value}] -> value
              {:error, _reason} -> 
                   key
            end
        :dets.close(dets)
        {:ok, r}
      {:error, _reason} -> 
                   #IO.inspect( {:error, _reason})
                   {:error, key}
    end
  end
  def gettext(app, key) do
    gettext(app, key, getlang())
  end
end
