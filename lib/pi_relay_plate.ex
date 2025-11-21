defmodule PiRelayPlate do
  @moduledoc """
  This is an Elixir library for the π Relay Plate.

  Product: https://pi-plates.com/product/relayplate/
    Documentation: https://pi-plates.com/relayplate-users-guide/
    Python library: https://github.com/pi-plates/PYTHONmodules/blob/master/RELAYplate.py

  ## Hardware

  Board id selection, hat must be completely powered off to select new id, boards are 0 indexed.
  - 0: 1+2, 3+4, 5+6
  - 3: 5+6
  - 7: all off

  Relay ids are 1 indexed, on the original hardware that means 1-7.

  ## Examples
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
  """

  alias Circuits.GPIO
  alias Circuits.SPI

  @max_board_id 7
  @number_of_relays 7
  @base_address 24
  @spi_options [speed_hz: 300_000, delay_us: 40]
  @default_options [pp_frame_pin: "GPIO25", pp_int_pin: "GPIO22", pp_ack_pin: "GPIO23"]

  @type board_id() :: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
  @type relay() :: 1 | 2 | 3 | 4 | 5 | 6 | 7
  @type board_state() :: [boolean()]
  @type t() :: %__MODULE__{
          options: Keyword.t(),
          pp_frame: Circuits.GPIO.Handle.t(),
          pp_int: Circuits.GPIO.Handle.t(),
          pp_ack: Circuits.GPIO.Handle.t(),
          spi_ref: Circuits.SPI.Bus.t(),
          board_id: board_id() | nil
        }

  defstruct [
    :options,
    :pp_frame,
    :pp_int,
    :pp_ack,
    :spi_ref,
    :board_id
  ]

  defguard is_board(board_id)
           when is_integer(board_id) and board_id >= 0 and board_id <= @max_board_id

  defguard is_relay(relay) when is_integer(relay) and relay >= 1 and relay <= @number_of_relays

  @doc """
  Starts opens the GPIO and SPI's required, returning a struct for control.

  ## Options
  The pins used are set by the board and should not be overwritten.

  If you pass in a :board_id it will be stored in the struct and used in
  the on/2, off/2 and toggle/2 functions.
  """
  @spec start(Keyword.t()) :: {:ok, t()} | {:error, term()}
  def start(opts \\ []) do
    opts = Keyword.merge(@default_options, opts)

    with {:ok, pp_frame} <- open_pp_frame(Keyword.get(opts, :pp_frame_pin)),
         {:ok, pp_int} <- open_pp_int(Keyword.get(opts, :pp_int_pin)),
         {:ok, pp_ack} <- open_pp_ack(Keyword.get(opts, :pp_ack_pin)),
         {:ok, spi_ref} <- Circuits.SPI.open("spidev0.1", @spi_options) do
      {:ok,
       %__MODULE__{
         options: opts,
         pp_frame: pp_frame,
         pp_int: pp_int,
         pp_ack: pp_ack,
         spi_ref: spi_ref,
         board_id: Keyword.get(opts, :board_id)
       }}
    end
  end

  @doc """
  Closes all the GPIO and SPI's that the RelayPlate holds on to.
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{} = relay_plate) do
    Circuits.SPI.close(relay_plate.spi_ref)
    Circuits.GPIO.close(relay_plate.pp_frame)
    Circuits.GPIO.close(relay_plate.pp_int)
    Circuits.GPIO.close(relay_plate.pp_ack)
    :ok
  end

  @doc """
  Turns on a relay.

  ## Examples
      iex> PiRelayPlate.on(relay, 1)
      :ok
      iex> PiRelayPlate.on(relay, 0, 1)
      :ok
  """
  @spec on(t(), relay()) :: :ok
  @spec on(t(), board_id(), relay()) :: :ok
  def on(%__MODULE__{board_id: board_id} = relay_plate, relay)
      when is_board(board_id) and is_relay(relay), do: on(relay_plate, board_id, relay)

  def on(%__MODULE__{} = relay_plate, board_id, relay)
      when is_board(board_id) and is_relay(relay),
      do: run_command(relay_plate, board_id, relay, :on)

  @doc """
  Turns off a relay.

  ## Examples
      iex> PiRelayPlate.off(relay, 1)
      :ok
      iex> PiRelayPlate.off(relay, 0, 1)
      :ok
  """
  @spec off(t(), relay()) :: :ok
  @spec off(t(), board_id(), relay()) :: :ok
  def off(%__MODULE__{board_id: board_id} = relay_plate, relay)
      when is_board(board_id) and is_relay(relay), do: off(relay_plate, board_id, relay)

  def off(%__MODULE__{} = relay_plate, board_id, relay)
      when is_board(board_id) and is_relay(relay),
      do: run_command(relay_plate, board_id, relay, :off)

  @doc """
  Toggles a relay.

  ## Examples
      iex> PiRelayPlate.toggle(relay, 1)
      :ok
      iex> PiRelayPlate.toggle(relay, 0, 1)
      :ok
  """
  @spec toggle(t(), relay()) :: :ok
  @spec toggle(t(), board_id(), relay()) :: :ok
  def toggle(%__MODULE__{board_id: board_id} = relay_plate, relay)
      when is_board(board_id) and is_relay(relay), do: toggle(relay_plate, board_id, relay)

  def toggle(%__MODULE__{} = relay_plate, board_id, relay)
      when is_board(board_id) and is_relay(relay),
      do: run_command(relay_plate, board_id, relay, :toggle)

  @doc """
  Turns on the main power LED.

  ## Examples
      iex> PiRelayPlate.led_on(relay)
      :ok
      iex> PiRelayPlate.led_on(relay, 0)
      :ok
  """
  @spec led_on(t()) :: :ok
  @spec led_on(t(), board_id()) :: :ok
  def led_on(%__MODULE__{board_id: board_id} = relay_plate) when is_board(board_id),
    do: led_on(relay_plate, board_id)

  def led_on(%__MODULE__{} = relay_plate, board_id) when is_board(board_id),
    do: run_command(relay_plate, board_id, 0, :led_on)

  @doc """
  Turns off the main power LED.

  ## Examples
      iex> PiRelayPlate.led_off(relay)
      :ok
      iex> PiRelayPlate.led_off(relay, 0)
      :ok
  """
  @spec led_off(t()) :: :ok
  @spec led_off(t(), board_id()) :: :ok
  def led_off(%__MODULE__{board_id: board_id} = relay_plate) when is_board(board_id),
    do: led_off(relay_plate, board_id)

  def led_off(%__MODULE__{} = relay_plate, board_id) when is_board(board_id),
    do: run_command(relay_plate, board_id, 0, :led_off)

  @doc """
  Toggles the main power LED.

  ## Examples
      iex> PiRelayPlate.led_toggle(relay)
      :ok
      iex> PiRelayPlate.led_toggle(relay, 0)
      :ok
  """
  @spec led_toggle(t()) :: :ok
  @spec led_toggle(t(), board_id()) :: :ok
  def led_toggle(%__MODULE__{board_id: board_id} = relay_plate) when is_board(board_id),
    do: led_toggle(relay_plate, board_id)

  def led_toggle(%__MODULE__{} = relay_plate, board_id) when is_board(board_id),
    do: run_command(relay_plate, board_id, 0, :led_toggle)

  @doc """
  Fetches the state of a boards relays.

  ## Examples
      iex> PiRelayPlate.on(relay, 2)
      :ok
      iex> PiRelayPlate.get_state(relay, 0)
      [false, true, false, false, false, false, false]
  """
  @spec get_state(t()) :: board_state()
  @spec get_state(t(), board_id()) :: board_state()
  def get_state(%__MODULE__{board_id: board_id} = relay_plate) when is_board(board_id),
    do: get_state(relay_plate, board_id)

  def get_state(%__MODULE__{} = relay_plate, board_id) when is_board(board_id) do
    start_write(relay_plate)
    SPI.transfer(relay_plate.spi_ref, construct_msg(board_id, 0, :state))

    val =
      relay_plate
      |> read_bytes(1)
      |> byte_to_list()
      # We only want 7 bits
      |> tl()
      # With bit ordering in the byte it is reversed from how we want it
      |> Enum.reverse()
      |> Enum.map(&if &1 == 1, do: true, else: false)

    stop_write(relay_plate)
    val
  end

  @doc """
  Fetches the id of the board.

  ## Examples
      iex> PiRelayPlate.get_id(relay, 0)
      "Pi-Plate RELAY"
  """
  @spec get_id(t(), board_id()) :: String.t()
  def get_id(%__MODULE__{} = relay_plate, board_id) when is_board(board_id) do
    start_write(relay_plate)
    SPI.transfer(relay_plate.spi_ref, construct_msg(board_id, 0, :id))
    :timer.sleep(1)
    val = relay_plate |> read_bytes(20) |> Enum.reject(&(&1 == <<0>>)) |> to_string()
    stop_write(relay_plate)
    val
  end

  defp run_command(relay_plate, board_id, relay, cmd) do
    start_write(relay_plate)
    SPI.transfer(relay_plate.spi_ref, construct_msg(board_id, relay, cmd))
    stop_write(relay_plate)
  end

  defp start_write(%{pp_frame: gpio}), do: Circuits.GPIO.write(gpio, 1)
  defp stop_write(%{pp_frame: gpio}), do: Circuits.GPIO.write(gpio, 0)

  defp read_bytes(relay_plate, count) do
    Enum.map(0..(count - 1), fn _ ->
      val = Circuits.SPI.transfer!(relay_plate.spi_ref, <<00>>)
      :timer.sleep(1)
      val
    end)
    |> List.flatten()
  end

  defp construct_msg(board_id, relay, cmd),
    do: <<@base_address + board_id, look_up_command(cmd), relay, 0>>

  defp look_up_command(:id), do: 0x1
  defp look_up_command(:on), do: 0x10
  defp look_up_command(:off), do: 0x11
  defp look_up_command(:toggle), do: 0x12
  defp look_up_command(:state), do: 0x14
  defp look_up_command(:led_on), do: 0x60
  defp look_up_command(:led_off), do: 0x61
  defp look_up_command(:led_toggle), do: 0x62

  defp byte_to_list([byte]), do: byte_to_list(byte)

  defp byte_to_list(<<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>>),
    do: [a, b, c, d, e, f, g, h]

  defp open_pp_frame(pin) do
    gpio = GPIO.open(pin, :output, initial_value: 0)
    # according to the original implementation: let Pi-Plate reset SPI engine if necessary
    :timer.sleep(10)
    gpio
  end

  defp open_pp_int(pin), do: GPIO.open(pin, :input, pull_mode: :pullup)
  defp open_pp_ack(pin), do: GPIO.open(pin, :input, pull_mode: :pullup)
end
