defmodule ExFiskal.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_fiskal,
      version: "0.1.2",
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
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
