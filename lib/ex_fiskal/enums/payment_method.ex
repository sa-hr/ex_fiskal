defmodule ExFiskal.Enums.PaymentMethod do
  @moduledoc """
  Payment method enums for fiscalization.

  Values:
  - G - cash (gotovina)
  - K - cards (kartice)
  - C - check (ček)
  - T - bank transfer (transakcijski račun)
  - O - other (ostalo)
  """

  @values ~w(G K C T O)

  def values, do: @values

  def cash, do: "G"
  def cards, do: "K"
  def check, do: "C"
  def bank_transfer, do: "T"
  def other, do: "O"

  def valid?(value) when value in @values, do: true
  def valid?(_), do: false
end
