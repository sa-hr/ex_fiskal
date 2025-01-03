defmodule ExFiskalTest do
  use ExUnit.Case
  doctest ExFiskal

  describe "fiscalize/3" do
    test "fiscalizes a sample request" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      params = %{
        tax_number: "23618229102",
        invoice_number: "1",
        business_unit: "1",
        device_number: "1",
        total_amount: 10000,
        vat: [
          %{rate: 2500, base: 10000, amount: 2000}
        ],
        operator_tax_number: "37501579645"
      }

      assert {:ok, _response} = ExFiskal.fiscalize(params, p12_binary, password)
    end
  end
end
