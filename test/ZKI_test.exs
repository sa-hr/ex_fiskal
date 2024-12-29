defmodule ExFiskal.ZKITest do
  use ExUnit.Case

  alias ExFiskal.ZKI

  @valid_password "ExamplePassword"
  @test_cert_path "priv/certificates/test.p12"

  setup do
    pkcs12_binary = File.read!(@test_cert_path)

    valid_params = %{
      tax_number: "12345678901",
      datetime: "01.01.2024T12:00:00",
      invoice_number: "1",
      business_unit: "POSLOVNICA1",
      device_number: "BLAG1",
      total_amount: "100.00"
    }

    {:ok, pkcs12_binary: pkcs12_binary, valid_params: valid_params}
  end

  describe "generate/3" do
    test "generates valid ZKI code", %{pkcs12_binary: pkcs12_binary, valid_params: params} do
      assert {:ok, zki} = ZKI.generate(params, pkcs12_binary, @valid_password)

      assert zki == "823b39a6c51200580aad54dc3f9adc16"
      assert is_binary(zki)
      assert String.length(zki) == 32
      assert String.match?(zki, ~r/^[a-f0-9]{32}$/)
    end

    test "returns error with invalid password", %{
      pkcs12_binary: pkcs12_binary,
      valid_params: params
    } do
      assert {:error, error} = ZKI.generate(params, pkcs12_binary, "WrongPassword")
      assert String.contains?(error, "Mac verify error")
    end

    test "returns error with invalid certificate data", %{valid_params: params} do
      assert {:error, _} = ZKI.generate(params, "invalid binary", @valid_password)
    end

    test "returns error with missing required params", %{pkcs12_binary: pkcs12_binary} do
      # Missing required fields
      invalid_params = %{tax_number: "12345678901"}

      assert_raise FunctionClauseError, fn ->
        ZKI.generate(invalid_params, pkcs12_binary, @valid_password)
      end
    end

    test "generates consistent ZKI for same input", %{
      pkcs12_binary: pkcs12_binary,
      valid_params: params
    } do
      assert {:ok, zki1} = ZKI.generate(params, pkcs12_binary, @valid_password)
      assert {:ok, zki2} = ZKI.generate(params, pkcs12_binary, @valid_password)
      assert zki1 == zki2
    end

    test "generates different ZKI for different inputs", %{
      pkcs12_binary: pkcs12_binary,
      valid_params: params
    } do
      assert {:ok, zki1} = ZKI.generate(params, pkcs12_binary, @valid_password)

      different_params = Map.put(params, :invoice_number, "2")
      assert {:ok, zki2} = ZKI.generate(different_params, pkcs12_binary, @valid_password)

      refute zki1 == zki2
    end
  end
end
