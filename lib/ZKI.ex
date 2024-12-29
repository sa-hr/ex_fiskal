defmodule ExFiskal.ZKI do
  @moduledoc """
  Handles generation of ZKI (zaštitni kod izdavatelja) for Croatian fiscalization.
  The ZKI is a security code that confirms the link between the fiscalization obligor and the issued receipt.
  """

  alias ExFiskal.PKCS12

  @doc """
  Generates ZKI code from the receipt data and PKCS12 certificate.

  Parameters:
  - params: Map containing required fields:
    - tax_number: Tax number (OIB)
    - datetime: Receipt datetime
    - invoice_number: Receipt sequence number
    - business_unit: Business unit identifier
    - device_number: Device identifier
    - total_amount: Total amount
  - p12_binary: PKCS12 certificate binary data
  - password: PKCS12 certificate password
  """
  def generate(params, p12_binary, password) do
    with {:ok, input_string} <- build_input_string(params),
         {:ok, signature} <- sign_string(input_string, p12_binary, password) do
      {:ok, generate_zki(signature)}
    end
  end

  defp build_input_string(%{
         tax_number: tax_number,
         datetime: datetime,
         invoice_number: invoice_number,
         business_unit: business_unit,
         device_number: device_number,
         total_amount: total_amount
       }) do
    datetime = String.replace(datetime, "T", " ")

    input =
      [
        tax_number,
        datetime,
        invoice_number,
        business_unit,
        device_number,
        total_amount
      ]
      |> Enum.join("")

    {:ok, input}
  end

  defp sign_string(string, p12_binary, password) do
    PKCS12.sign_string(string, p12_binary, password)
  end

  defp generate_zki(signature) do
    signature
    |> Base.decode64!()
    |> :erlang.md5()
    |> Base.encode16(case: :lower)
  end
end