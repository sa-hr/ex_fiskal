defmodule ExFiskalTest do
  use ExUnit.Case
  doctest ExFiskal

  describe "fiscalize!/2" do
    test "fiscalizes a sample request" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      params = %{
        message_id: "0f57be5c-bd63-4f17-a982-dbe5d43369ad",
        tax_number: "23618229102",
        invoice_number: "1",
        business_unit: "1",
        device_number: "1",
        datetime: ~U[2024-01-01 12:00:00Z],
        invoice_datetime: ~U[2024-01-01 12:00:00Z],
        total_amount: 10000,
        vat: [
          %{rate: 2500, base: 10000, amount: 2000}
        ],
        operator_tax_number: "37501579645"
      }

      certificate_data = ExFiskal.extract_certificate_data!(p12_binary, password)

      assert {:ok, zki, response} = ExFiskal.fiscalize!(params, certificate_data)

      assert zki == "e3008f5f76e006d638803877f70dfbe4"

      assert_response = File.read!("priv/examples/final_request.xml")
      assert response == assert_response
    end
  end
end
