defmodule ExFiskal.ZKITest do
  use ExUnit.Case

  alias ExFiskal.ZKI

  setup do
    pkcs12_binary = File.read!("priv/certificates/test.p12")

    valid_params = %{
      tax_number: "12345678901",
      datetime: "01.01.2024T12:00:00",
      invoice_number: "1",
      business_unit: "POSLOVNICA1",
      device_number: "BLAG1",
      total_amount: "100.00"
    }

    certificate_data =
      ExFiskal.Cryptography.extract_certificate_data!(pkcs12_binary, "ExamplePassword")

    {:ok, certificate_data: certificate_data, valid_params: valid_params}
  end

  describe "generate/3" do
    test "generates valid ZKI code", %{certificate_data: certificate_data, valid_params: params} do
      zki = ZKI.generate!(params, certificate_data)

      assert zki == "823b39a6c51200580aad54dc3f9adc16"
      assert is_binary(zki)
      assert String.length(zki) == 32
      assert String.match?(zki, ~r/^[a-f0-9]{32}$/)
    end

    test "generates consistent ZKI for same input", %{
      certificate_data: certificate_data,
      valid_params: params
    } do
      assert zki1 = ZKI.generate!(params, certificate_data)
      assert zki2 = ZKI.generate!(params, certificate_data)
      assert zki1 == zki2
    end

    test "generates different ZKI for different inputs", %{
      certificate_data: certificate_data,
      valid_params: params
    } do
      assert zki1 = ZKI.generate!(params, certificate_data)

      different_params = Map.put(params, :invoice_number, "2")
      assert zki2 = ZKI.generate!(different_params, certificate_data)

      refute zki1 == zki2
    end
  end
end
