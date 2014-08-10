defmodule Exgettext.Runtime do
  def basedir(app) do
    case :code.lib_dir(app) do
      {:error, _other} -> ""
      r -> r
    end
  end
  def mofile(app, lang) do
    Path.join([basedir(app), "priv", "lang", "#{lang}", "#{app}.exmo"])
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
  def getlang() do
    case Exgettext.getlocale() do
      nil -> 
        getlang(System.get_env("LANG"))
      r -> 
        r
    end
  end
  def gettext(app, key, lang) do
    r = case gettext_raw(app, key, lang) do
          {:ok, r} -> r
          _ ->
            {_, r} = gettext_raw(:"l10n_#{app}", key, lang)
            r
        end
    r
  end
  def gettext_raw(app, key, lang) do
    dets_file = getpath(app, lang)
    case :dets.open_file(dets_file) do
      {:ok, dets} ->
        r = case :dets.lookup(dets, key) do
              [] -> key
              [{^key, ""}] -> key
              [{^key, value}] -> value
              {:error, _reason} -> key
            end
        :dets.close(dets)
        {:ok, r}
      {:error, _reason} ->
        {:error, key}
    end
  end
  def gettext(app, key) do
    gettext(app, key, getlang())
  end
end
