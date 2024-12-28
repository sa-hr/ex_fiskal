defmodule ExFiskal.RequestTemplateTest do
  use ExUnit.Case
  alias ExFiskal.RequestTemplate

  @minimal_params %{
    message_id: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    datetime: "01.09.2012T21:10:34",
    tax_number: "98765432198",
    in_vat_system: true,
    invoice_datetime: "01.09.2012T21:10:34",
    sequence_mark: "P",
    invoice_number: "123456789",
    business_unit: "POSL1",
    device_number: "12",
    total_amount: "30.00",
    payment_method: "K",
    operator_tax_number: "01234567890",
    security_code: "e4d909c290d0fb1ca068ffaddf22cbd0",
    subsequent_delivery: false
  }

  describe "generate/1 with minimal required fields" do
    test "generates valid XML with only required fields" do
      result = RequestTemplate.generate(@minimal_params)
      assert result =~ ~r/<tns:RacunZahtjev/
      assert result =~ ~r/<tns:IdPoruke>#{@minimal_params.message_id}<\/tns:IdPoruke>/
      assert result =~ ~r/<tns:DatumVrijeme>#{@minimal_params.datetime}<\/tns:DatumVrijeme>/
      assert result =~ ~r/<tns:Oib>#{@minimal_params.tax_number}<\/tns:Oib>/
      assert result =~ ~r/<tns:USustPdv>true<\/tns:USustPdv>/
      refute result =~ ~r/<tns:Pdv>/
      refute result =~ ~r/<tns:Pnp>/
      refute result =~ ~r/<tns:OstaliPor>/
      refute result =~ ~r/<tns:IznosOslobPdv>/
      refute result =~ ~r/<tns:IznosMarza>/
      refute result =~ ~r/<tns:Naknade>/
      refute result =~ ~r/<tns:ParagonBrRac>/
      refute result =~ ~r/<tns:SpecNamj>/
    end

    test "validates required fields are present" do
      for key <- Map.keys(@minimal_params) do
        params = Map.delete(@minimal_params, key)

        assert_raise KeyError, fn ->
          RequestTemplate.generate(params)
        end
      end
    end
  end

  describe "generate/1 with VAT" do
    test "includes single VAT entry when provided" do
      params =
        Map.put(@minimal_params, :vat, [
          %{rate: "25.00", base: "100.00", amount: "25.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:Pdv>/
      assert result =~ ~r/<tns:Stopa>25.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Osnovica>100.00<\/tns:Osnovica>/
      assert result =~ ~r/<tns:Iznos>25.00<\/tns:Iznos>/
    end

    test "includes multiple VAT entries when provided" do
      params =
        Map.put(@minimal_params, :vat, [
          %{rate: "25.00", base: "100.00", amount: "25.00"},
          %{rate: "13.00", base: "50.00", amount: "6.50"},
          %{rate: "5.00", base: "20.00", amount: "1.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:Stopa>25.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Stopa>13.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Stopa>5.00<\/tns:Stopa>/
    end

    test "omits VAT section when empty list provided" do
      params = Map.put(@minimal_params, :vat, [])
      result = RequestTemplate.generate(params)
      refute result =~ ~r/<tns:Pdv>/
    end
  end

  describe "generate/1 with consumption tax" do
    test "includes single consumption tax entry when provided" do
      params =
        Map.put(@minimal_params, :consumption_tax, [
          %{rate: "3.00", base: "100.00", amount: "3.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:Pnp>/
      assert result =~ ~r/<tns:Stopa>3.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Osnovica>100.00<\/tns:Osnovica>/
      assert result =~ ~r/<tns:Iznos>3.00<\/tns:Iznos>/
    end

    test "includes multiple consumption tax entries when provided" do
      params =
        Map.put(@minimal_params, :consumption_tax, [
          %{rate: "3.00", base: "100.00", amount: "3.00"},
          %{rate: "2.00", base: "50.00", amount: "1.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:Stopa>3.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Stopa>2.00<\/tns:Stopa>/
    end

    test "omits consumption tax section when empty list provided" do
      params = Map.put(@minimal_params, :consumption_tax, [])
      result = RequestTemplate.generate(params)
      refute result =~ ~r/<tns:Pnp>/
    end
  end

  describe "generate/1 with other taxes" do
    test "includes single other tax entry when provided" do
      params =
        Map.put(@minimal_params, :other_taxes, [
          %{name: "Luxury Tax", rate: "10.00", base: "1000.00", amount: "100.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:OstaliPor>/
      assert result =~ ~r/<tns:Naziv>Luxury Tax<\/tns:Naziv>/
      assert result =~ ~r/<tns:Stopa>10.00<\/tns:Stopa>/
      assert result =~ ~r/<tns:Osnovica>1000.00<\/tns:Osnovica>/
      assert result =~ ~r/<tns:Iznos>100.00<\/tns:Iznos>/
    end

    test "omits other taxes section when empty list provided" do
      params = Map.put(@minimal_params, :other_taxes, [])
      result = RequestTemplate.generate(params)
      refute result =~ ~r/<tns:OstaliPor>/
    end
  end

  describe "generate/1 with fees" do
    test "includes single fee entry when provided" do
      params =
        Map.put(@minimal_params, :fees, [
          %{name: "Return Fee", amount: "10.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:Naknade>/
      assert result =~ ~r/<tns:NazivN>Return Fee<\/tns:NazivN>/
      assert result =~ ~r/<tns:IznosN>10.00<\/tns:IznosN>/
    end

    test "includes multiple fee entries when provided" do
      params =
        Map.put(@minimal_params, :fees, [
          %{name: "Return Fee", amount: "10.00"},
          %{name: "Service Fee", amount: "5.00"}
        ])

      result = RequestTemplate.generate(params)
      assert result =~ ~r/Return Fee.*Service Fee/s
    end

    test "omits fees section when empty list provided" do
      params = Map.put(@minimal_params, :fees, [])
      result = RequestTemplate.generate(params)
      refute result =~ ~r/<tns:Naknade>/
    end
  end

  describe "generate/1 with optional single fields" do
    test "includes VAT free amount when provided" do
      params = Map.put(@minimal_params, :vat_free_amount, "50.00")
      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:IznosOslobPdv>50.00<\/tns:IznosOslobPdv>/
    end

    test "includes margin amount when provided" do
      params = Map.put(@minimal_params, :margin_amount, "25.00")
      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:IznosMarza>25.00<\/tns:IznosMarza>/
    end

    test "includes paragon number when provided" do
      params = Map.put(@minimal_params, :paragon_number, "123/45")
      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:ParagonBrRac>123\/45<\/tns:ParagonBrRac>/
    end

    test "includes special purpose when provided" do
      params = Map.put(@minimal_params, :special_purpose, "Test purpose")
      result = RequestTemplate.generate(params)
      assert result =~ ~r/<tns:SpecNamj>Test purpose<\/tns:SpecNamj>/
    end
  end

  describe "generate/1 with all fields" do
    test "generates complete XML with all optional fields" do
      params =
        @minimal_params
        |> Map.put(:vat, [%{rate: "25.00", base: "100.00", amount: "25.00"}])
        |> Map.put(:consumption_tax, [%{rate: "3.00", base: "100.00", amount: "3.00"}])
        |> Map.put(:other_taxes, [
          %{name: "Luxury Tax", rate: "10.00", base: "1000.00", amount: "100.00"}
        ])
        |> Map.put(:fees, [%{name: "Return Fee", amount: "10.00"}])
        |> Map.put(:vat_free_amount, "50.00")
        |> Map.put(:margin_amount, "25.00")
        |> Map.put(:paragon_number, "123/45")
        |> Map.put(:special_purpose, "Test purpose")

      result = RequestTemplate.generate(params)

      assert result =~ ~r/<tns:Pdv>/
      assert result =~ ~r/<tns:Pnp>/
      assert result =~ ~r/<tns:OstaliPor>/
      assert result =~ ~r/<tns:Naknade>/
      assert result =~ ~r/<tns:IznosOslobPdv>/
      assert result =~ ~r/<tns:IznosMarza>/
      assert result =~ ~r/<tns:ParagonBrRac>/
      assert result =~ ~r/<tns:SpecNamj>/
    end
  end

  describe "generate/1 with payment methods" do
    test "handles all valid payment methods" do
      payment_methods = ["G", "K", "C", "T", "O"]

      for method <- payment_methods do
        params = Map.put(@minimal_params, :payment_method, method)
        result = RequestTemplate.generate(params)
        assert result =~ ~r/<tns:NacinPlac>#{method}<\/tns:NacinPlac>/
      end
    end
  end

  describe "generate/1 with official examples" do
    test "Example 1" do
      params = %{
        message_id: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
        datetime: "01.09.2012T21:10:34",
        tax_number: "98765432198",
        in_vat_system: true,
        invoice_datetime: "01.09.2012T21:10:34",
        sequence_mark: "P",
        invoice_number: "123456789",
        business_unit: "POSL1",
        device_number: "12",
        vat: [
          %{
            rate: "25.00",
            base: "10.00",
            amount: "2.50"
          },
          %{
            rate: "10.00",
            base: "10.00",
            amount: "1.00"
          },
          %{
            rate: "0.00",
            base: "10.00",
            amount: "0.00"
          }
        ],
        consumption_tax: [
          %{
            rate: "3.00",
            base: "10.00",
            amount: "0.30"
          }
        ],
        other_taxes: [
          %{
            name: "Porez na luksuz",
            rate: "15.00",
            base: "10.00",
            amount: "1.50"
          }
        ],
        vat_free_amount: "12.00",
        margin_amount: "13.00",
        fees: [
          %{
            name: "Povratna naknada",
            amount: "1.00"
          }
        ],
        total_amount: "30.00",
        payment_method: "K",
        operator_tax_number: "01234567890",
        security_code: "e4d909c290d0fb1ca068ffaddf22cbd0",
        subsequent_delivery: false,
        paragon_number: "123/458/5",
        special_purpose: "Navedeno kao primjer"
      }

      request =
        RequestTemplate.generate(params) |> String.replace("\n", "") |> String.replace(" ", "")

      example =
        File.read!("priv/examples/request-1.xml")
        |> String.replace("\n", "")
        |> String.replace(" ", "")

      assert request == example
    end
  end
end
