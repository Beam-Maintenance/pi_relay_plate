defmodule PiRelayPlate.MixProject do
  use Mix.Project

  @github_url "https://github.com/Beam-Maintenance/pi_relay_plate"
  @version "0.1.0"

  def project do
    [
      app: :pi_relay_plate,
      name: "Pi Relay Plate",
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      source_url: @github_url,
      package: package(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "This is an Elixir library for the π Relay Plate. https://pi-plates.com/product/relayplate/"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "PiRelayPlate",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # dev
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},
      # eveything else
      {:circuits_gpio, "~> 2.1"},
      {:circuits_spi, "~> 2.0"}
    ]
  end
end
