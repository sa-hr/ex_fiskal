defmodule ExFiskal.Enums.SequenceMark do
  @moduledoc """
  Sequence mark enums for fiscalization.

  Values:
  - P - business unit level (na nivou poslovnog prostora)
  - N - device level (na nivou naplatnog uređaja)
  """

  @values ~w(P N)

  def values, do: @values

  def business_unit, do: "P"
  def device, do: "N"

  def valid?(value) when value in @values, do: true
  def valid?(_), do: false
end
