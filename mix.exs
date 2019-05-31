defmodule Exgettext.Mixfile do
  use Mix.Project

  def project do
    [app: :exgettext,
     version: "0.1.1",
#     elixir: "~> 1.1.0-beta or ~> 1.0.0 or ~> 0.15.0-dev",
     compilers: Mix.compilers ++ [:po],
     description: "Localization package using GNU gettext",
     source_url: "https://github.com/k1complete/exgettext/",
     source_root: ".",
     docs: [
       formatter: Exgettext.HTML
     ],
     package: [
               contributors: ["k1complete"],
               licenses: ["MIT"],
               links: %{"GitHub" => "https://github.com/k1complete/exgettext"}
       ],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: []]
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_doc, git: "https://github.com/elixir-lang/ex_doc.git"}]
  end
end
