defmodule ExFiskal do
  @moduledoc """
  Documentation for `ExFiskal`.
  """

  alias ExFiskal.{RequestParams, RequestTemplate, ZKI, RequestXML, Cryptorgaphy, CertificateData}

  @doc """
  Fiscalizes the recepit taking in params and the extracted private key and public certificate.

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

  # First extract the certificate keys
  certificate_data = ExFiskal.extract_certificate_data!(certificate, password)

  # Then fiscalize with the extracted keys
  ExFiskal.fiscalize(params, certificate_data)
  ```
  """
  def fiscalize!(params, certificate_data) do
    certificate_data = CertificateData.new(certificate_data)

    with {:ok, params} <- RequestParams.new(params) do
      zki = ZKI.generate!(params, certificate_data)

      request =
        params
        |> Map.put(:security_code, zki)
        |> RequestTemplate.generate_request()
        |> RequestXML.process_request!(certificate_data)

      {:ok, zki, request}
    end
  end

  def extract_certificate_data!(certificate, password) do
    Cryptorgaphy.extract_certificate_data!(certificate, password)
  end
end
