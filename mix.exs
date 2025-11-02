defmodule ExFiskal.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_fiskal,
      version: "0.2.2",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "ExFiskal",
      source_url: "https://github.com/sa-hr/ex_fiskal",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ExFiskal.Application, []},
      extra_applications: [:xmerl, :logger]
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:xmerl_c14n, "~> 0.1.0"},
      {:xml_builder, "~> 2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:pythonx, "~> 0.4.0"},
      {:jason, "~> 1.2"}
    ]
  end

  defp description do
    "Library for creating fiscalized receiptes as per Croatian fiscalization"
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sa-hr/ex_fiskal"}
    ]
  end
end
