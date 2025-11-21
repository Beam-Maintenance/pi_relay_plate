# PiRelayPlate

This is an Elixir library for the π Relay Plate.

- Product: https://pi-plates.com/product/relayplate/
- Documentation: https://pi-plates.com/relayplate-users-guide/
- Python library: https://github.com/pi-plates/PYTHONmodules/blob/master/RELAYplate.py

## Examples
```elixir
iex> {:ok, relay} = PiRelayPlate.start()
{:ok,
  %PiRelayPlate{
    options: [
      pp_frame_pin: "GPIO25",
      pp_int_pin: "GPIO22",
      pp_ack_pin: "GPIO23",
      board_id: 0
    ],
    pp_frame: %Circuits.GPIO.CDev{ref: #Reference<...>},
    pp_int: %Circuits.GPIO.CDev{ref: #Reference<...>},
    pp_ack: %Circuits.GPIO.CDev{ref: #Reference<...>},
    spi_ref: %Circuits.SPI.SPIDev{ref: #Reference<...>},
    board_id: 0
  }}
iex> PiRelayPlate.toggle(relay, 1)
:ok
iex> RelayPlate.stop(relay)
:ok
```
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pi_relay_plate` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pi_relay_plate, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pi_relay_plate>.
