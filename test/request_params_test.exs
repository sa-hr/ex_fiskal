defmodule ExFiskal.RequestParamsTest do
  use ExUnit.Case
  doctest ExFiskal.RequestParams

  alias ExFiskal.RequestParams
  alias ExFiskal.Enums.{PaymentMethod, SequenceMark}

  @valid_params %{
    tax_number: "12345678901",
    invoice_number: "1",
    business_unit: "STORE1",
    device_number: "1",
    total_amount: 10000,
    operator_tax_number: "98765432109",
    security_code: "01234567890123456789012345678901"
  }

  describe "new/1" do
    test "creates valid params with minimal required fields" do
      assert {:ok, params} = RequestParams.new(@valid_params)
      assert params.tax_number == "12345678901"
      assert params.invoice_number == "1"
      assert params.business_unit == "STORE1"
      assert params.device_number == "1"
      assert params.total_amount == 10000
      assert params.operator_tax_number == "98765432109"
      assert params.security_code == "01234567890123456789012345678901"
    end

    test "applies default values" do
      {:ok, params} = RequestParams.new(@valid_params)
      assert is_binary(params.message_id)
      assert String.length(params.message_id) == 36
      assert params.in_vat_system == true
      assert params.sequence_mark == SequenceMark.business_unit()
      assert params.payment_method == PaymentMethod.cards()
      assert params.subsequent_delivery == false
      assert params.vat == []
      assert params.consumption_tax == []
      assert params.other_taxes == []
      assert params.fees == []
      assert is_nil(params.vat_free_amount)
      assert is_nil(params.margin_amount)
      assert is_nil(params.non_taxable_amount)
      assert is_nil(params.paragon_number)
      assert is_nil(params.special_purpose)
    end

    test "converts string amounts to integers (cents)" do
      params =
        Map.merge(@valid_params, %{
          total_amount: "100.50",
          vat_free_amount: "50.10",
          margin_amount: "25.00",
          non_taxable_amount: "10"
        })

      {:ok, validated} = RequestParams.new(params)
      assert validated.total_amount == 10050
      assert validated.vat_free_amount == 5010
      assert validated.margin_amount == 2500
      assert validated.non_taxable_amount == 1000
    end

    test "handles datetime values" do
      dt = ~N[2024-03-21 15:30:00]
      params = Map.put(@valid_params, :invoice_datetime, dt)

      {:ok, validated} = RequestParams.new(params)
      assert validated.invoice_datetime == "21.03.2024T15:30:00"
    end

    test "accepts and validates VAT entries" do
      params =
        Map.put(@valid_params, :vat, [
          %{rate: 2500, base: 8000, amount: 2000},
          %{rate: 1300, base: 10000, amount: 1300}
        ])

      {:ok, validated} = RequestParams.new(params)
      assert length(validated.vat) == 2
      [vat1, vat2] = validated.vat
      assert vat1.rate == 2500
      assert vat2.rate == 1300
    end

    test "accepts and validates consumption tax entries" do
      params =
        Map.put(@valid_params, :consumption_tax, [
          %{rate: 1000, base: 10000, amount: 1000}
        ])

      {:ok, validated} = RequestParams.new(params)
      assert length(validated.consumption_tax) == 1
      [tax] = validated.consumption_tax
      assert tax.rate == 1000
    end

    test "accepts and validates other tax entries" do
      params =
        Map.put(@valid_params, :other_taxes, [
          %{name: "City tax", rate: 500, base: 10000, amount: 500}
        ])

      {:ok, validated} = RequestParams.new(params)
      assert length(validated.other_taxes) == 1
      [tax] = validated.other_taxes
      assert tax.name == "City tax"
      assert tax.rate == 500
    end

    test "accepts and validates fee entries" do
      params =
        Map.put(@valid_params, :fees, [
          %{name: "Service fee", amount: 1000}
        ])

      {:ok, validated} = RequestParams.new(params)
      assert length(validated.fees) == 1
      [fee] = validated.fees
      assert fee.name == "Service fee"
      assert fee.amount == 1000
    end
  end

  describe "validation errors" do
    test "requires tax_number to be 11 digits" do
      params = Map.put(@valid_params, :tax_number, "123")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:tax_number] == "has invalid format"
    end

    test "requires invoice_number to be a positive integer" do
      params = Map.put(@valid_params, :invoice_number, "0")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:invoice_number] == "has invalid format"
    end

    test "requires business_unit to be alphanumeric" do
      params = Map.put(@valid_params, :business_unit, "STORE-1")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:business_unit] == "has invalid format"
    end

    test "requires device_number to be a positive integer" do
      params = Map.put(@valid_params, :device_number, "0")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:device_number] == "has invalid format"
    end

    test "validates amount is integer" do
      params = Map.put(@valid_params, :total_amount, 100.50)
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:total_amount] == "must be an integer representing cents"
    end

    test "validates VAT rate is integer percentage * 100" do
      params =
        Map.put(@valid_params, :vat, [
          %{rate: 25.5, base: 10000, amount: 2550}
        ])

      assert {:error, errors} = RequestParams.new(params)
      assert errors[:vat] == "has invalid format"
    end

    test "validates payment method values" do
      params = Map.put(@valid_params, :payment_method, "X")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:payment_method] == "has invalid value"
    end

    test "validates sequence mark values" do
      params = Map.put(@valid_params, :sequence_mark, "X")
      assert {:error, errors} = RequestParams.new(params)
      assert errors[:sequence_mark] == "has invalid value"
    end
  end

  describe "new/1 with official examples" do
    test "Example 1" do
      input = %{
        message_id: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
        datetime: ~N[2012-09-01 21:10:34],
        tax_number: "98765432198",
        in_vat_system: true,
        invoice_datetime: ~N[2012-09-01 21:10:34],
        sequence_mark: "P",
        invoice_number: "123456789",
        business_unit: "POSL1",
        device_number: "12",
        vat: [
          %{
            rate: 2500,
            base: 1000,
            amount: 250
          },
          %{
            rate: 1000,
            base: 1000,
            amount: 100
          },
          %{
            rate: 0,
            base: 1000,
            amount: 0
          }
        ],
        consumption_tax: [
          %{
            rate: 300,
            base: 1000,
            amount: 30
          }
        ],
        other_taxes: [
          %{
            name: "Porez na luksuz",
            rate: 1500,
            base: 1000,
            amount: 150
          }
        ],
        vat_free_amount: 1200,
        margin_amount: 1300,
        fees: [
          %{
            name: "Povratna naknada",
            amount: 100
          }
        ],
        total_amount: 3000,
        payment_method: "K",
        operator_tax_number: "01234567890",
        security_code: "e4d909c290d0fb1ca068ffaddf22cbd0",
        subsequent_delivery: false,
        paragon_number: "123/458/5",
        special_purpose: "Navedeno kao primjer"
      }

      {:ok, result} = ExFiskal.RequestParams.new(input)

      assert result.message_id == "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
      assert result.datetime == "01.09.2012T21:10:34"
      assert result.tax_number == "98765432198"
      assert result.in_vat_system == true
      assert result.invoice_datetime == "01.09.2012T21:10:34"
      assert result.sequence_mark == "P"
      assert result.invoice_number == "123456789"
      assert result.business_unit == "POSL1"
      assert result.device_number == "12"

      [vat1, vat2, vat3] = result.vat
      assert vat1 == %{rate: 2500, base: 1000, amount: 250}
      assert vat2 == %{rate: 1000, base: 1000, amount: 100}
      assert vat3 == %{rate: 0, base: 1000, amount: 0}

      [consumption] = result.consumption_tax
      assert consumption == %{rate: 300, base: 1000, amount: 30}

      [other_tax] = result.other_taxes

      assert other_tax == %{
               name: "Porez na luksuz",
               rate: 1500,
               base: 1000,
               amount: 150
             }

      assert result.vat_free_amount == 1200
      assert result.margin_amount == 1300

      [fee] = result.fees
      assert fee == %{name: "Povratna naknada", amount: 100}

      assert result.total_amount == 3000
      assert result.payment_method == "K"
      assert result.operator_tax_number == "01234567890"
      assert result.security_code == "e4d909c290d0fb1ca068ffaddf22cbd0"
      assert result.subsequent_delivery == false
      assert result.paragon_number == "123/458/5"
      assert result.special_purpose == "Navedeno kao primjer"
    end
  end
end
