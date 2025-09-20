defmodule ExFiskal do
  @moduledoc """
  Documentation for `ExFiskal`.
  """

  alias ExFiskal.{RequestParams, RequestTemplate, ZKI, RequestXML}

  @doc """
  Fiscalizes the recepit taking in params and the certificate and it's password.

  ## Example

  The following is the "minimal" example for fiscalizing a recepit/invoice.

  You will need:

  - Tax number (OIB) of the entity issuing the invoice (d.o.o., j.d.o.o., obrt, or d.d.)
  - Tax number (OIB) of the operator
  - Certificate from Fina in P12 format and it's password

  ```
  params = %{
    tax_number: "23618229102",
    invoice_number: "1",
    business_unit: "1",
    device_number: "1",
    total_amount: 10000,
    invoice_datetime: ~U[2024-12-12 14:46:49.258317Z],
    sequence_mark: ExFiskal.Enums.SequenceMark.business_unit(),
    payment_method: ExFiskal.Enums.PaymentMethod.cards(),
    vat: [
      %{rate: 2500, base: 10000, amount: 2000}
    ],
    operator_tax_number: "37501579645",
  }

  certificate = File.read!("/tmp/cert.p12")
  password = "ExamplePassword"

  ExFiskal.fiscalize(params, certificate, password)
  ```
  """
  def fiscalize(params, certificate, password) do
    with {:ok, params} <- RequestParams.new(params),
         {:ok, zki} <- ZKI.generate(params, certificate, password),
         params <- Map.put(params, :security_code, zki),
         request <- RequestTemplate.generate_request(params),
         {:ok, request} <- RequestXML.process_request(request, certificate, password) do
      {:ok, zki, request}
    end
  end
end
