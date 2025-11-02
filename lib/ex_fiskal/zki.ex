defmodule ExFiskal.ZKI do
  @moduledoc """
  Handles generation of ZKI (zaštitni kod izdavatelja) for Croatian fiscalization.
  The ZKI is a security code that confirms the link between the fiscalization obligor and the issued receipt.
  """

  alias ExFiskal.{CertificateData, Cryptography}

  def generate!(params, %CertificateData{key: private_key}) do
    input_string = build_input_string(params)
    signature = Cryptography.sign_string!(input_string, private_key)

    signature
    |> Base.decode64!()
    |> :erlang.md5()
    |> Base.encode16(case: :lower)
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

    [
      tax_number,
      datetime,
      invoice_number,
      business_unit,
      device_number,
      total_amount
    ]
    |> Enum.join("")
  end
end
