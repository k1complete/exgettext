defmodule Exgettext.Runtime do
  def basedir(app) do
    :code.lib_dir(app)
  end
  def mofile(app, lang) do
    Path.join([basedir(app), "priv", "lang", "#{lang}", "#{app}.exmo"])
  end
  def getpath(app, lang) do
    mofile(app, lang)
  end
  def locale_to_lang("C") do
    "en"
  end
  def locale_to_lang(nil) do
    "en"
  end
  def locale_to_lang(locale) do
    case Regex.run(~r/([^._]+)_([^._]+)\.([^.])+/, locale) do
      nil -> locale
      [^locale, lang, _country, _encoding] -> 
        lang
    end
  end
  def getlang() do
    locale_to_lang(System.get_env("LANG"))
  end
  def gettext(app, key, lang) do
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
        r
      {:error, _reason} ->
        key
    end
  end
  def gettext(app, key) do
    gettext(app, key, getlang())
  end
end
