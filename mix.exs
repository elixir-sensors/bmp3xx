defmodule BMP3XX.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mnishiguchi/bmp3xx"

  def project do
    [
      app: :bmp3xx,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: code(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp code(:test), do: ["lib", "test/support"]
  defp code(_), do: ["lib"]

  defp description do
    "Use Bosch BMP388 and BMP390 sensors in Elixir"
  end

  defp package do
    %{
      files: [
        "lib",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:i2c_server, "~> 0.2"},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
