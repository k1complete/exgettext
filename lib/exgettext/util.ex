defmodule Exgettext.Util do
  def popath(suffix \\ "") do
    Path.join(["priv", "po", suffix])
  end
  def poxfile(_app, lang) do
    popath("#{lang}.pox")
  end
  def pofile(_app, lang) do
    popath("#{lang}.po")
  end
  def pot_file(app) do
    popath("#{app}.pot")
  end
  def relative(file, path) do
    Path.relative_to(file, path)
  end
end
