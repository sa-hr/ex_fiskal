defmodule ExFiskal.RequestTemplate do
  import XmlBuilder

  def generate_request(params) do
    params = set_defaults(params)

    [
      element(:"tns:Zaglavlje", get_header(params)),
      element(:"tns:Racun", get_invoice(params))
    ]
  end

  defp get_header(params) do
    [
      element(:"tns:IdPoruke", params.message_id),
      element(:"tns:DatumVrijeme", params.datetime)
    ]
  end

  defp get_invoice(params) do
    base_elements = [
      element(:"tns:Oib", params.tax_number),
      element(:"tns:USustPdv", params.in_vat_system),
      element(:"tns:DatVrijeme", params.invoice_datetime),
      element(:"tns:OznSlijed", params.sequence_mark),
      element(:"tns:BrRac", [
        element(:"tns:BrOznRac", params.invoice_number),
        element(:"tns:OznPosPr", params.business_unit),
        element(:"tns:OznNapUr", params.device_number)
      ])
    ]

    optional_elements =
      []
      |> maybe_add_vat(params.vat)
      |> maybe_add_consumption_tax(params.consumption_tax)
      |> maybe_add_other_taxes(params.other_taxes)
      |> maybe_add_element(:"tns:IznosOslobPdv", params.vat_free_amount)
      |> maybe_add_element(:"tns:IznosMarza", params.margin_amount)
      |> maybe_add_element(:"tns:IznosNePodlOpor", params.non_taxable_amount)
      |> maybe_add_fees(params.fees)

    required_elements = [
      element(:"tns:IznosUkupno", params.total_amount),
      element(:"tns:NacinPlac", params.payment_method),
      element(:"tns:OibOper", params.operator_tax_number),
      element(:"tns:ZastKod", params.security_code),
      element(:"tns:NakDost", params.subsequent_delivery)
    ]

    final_elements =
      []
      |> maybe_add_element(:"tns:ParagonBrRac", params.paragon_number)
      |> maybe_add_element(:"tns:SpecNamj", params.special_purpose)

    base_elements ++ optional_elements ++ required_elements ++ final_elements
  end

  defp set_defaults(params) do
    Map.merge(
      %{
        vat: [],
        consumption_tax: [],
        other_taxes: [],
        fees: [],
        vat_free_amount: nil,
        margin_amount: nil,
        non_taxable_amount: nil,
        paragon_number: nil,
        special_purpose: nil
      },
      params
    )
  end

  defp maybe_add_vat(elements, nil), do: elements
  defp maybe_add_vat(elements, []), do: elements

  defp maybe_add_vat(elements, vat_items) do
    vat_elements =
      Enum.map(vat_items, fn item ->
        element(:"tns:Porez", [
          element(:"tns:Stopa", item.rate),
          element(:"tns:Osnovica", item.base),
          element(:"tns:Iznos", item.amount)
        ])
      end)

    elements ++ [element(:"tns:Pdv", vat_elements)]
  end

  defp maybe_add_consumption_tax(elements, nil), do: elements
  defp maybe_add_consumption_tax(elements, []), do: elements

  defp maybe_add_consumption_tax(elements, tax_items) do
    tax_elements =
      Enum.map(tax_items, fn item ->
        element(:"tns:Porez", [
          element(:"tns:Stopa", item.rate),
          element(:"tns:Osnovica", item.base),
          element(:"tns:Iznos", item.amount)
        ])
      end)

    elements ++ [element(:"tns:Pnp", tax_elements)]
  end

  defp maybe_add_other_taxes(elements, nil), do: elements
  defp maybe_add_other_taxes(elements, []), do: elements

  defp maybe_add_other_taxes(elements, tax_items) do
    tax_elements =
      Enum.map(tax_items, fn item ->
        element(:"tns:Porez", [
          element(:"tns:Naziv", item.name),
          element(:"tns:Stopa", item.rate),
          element(:"tns:Osnovica", item.base),
          element(:"tns:Iznos", item.amount)
        ])
      end)

    elements ++ [element(:"tns:OstaliPor", tax_elements)]
  end

  defp maybe_add_fees(elements, nil), do: elements
  defp maybe_add_fees(elements, []), do: elements

  defp maybe_add_fees(elements, fee_items) do
    fee_elements =
      Enum.map(fee_items, fn item ->
        element(:"tns:Naknada", [
          element(:"tns:NazivN", item.name),
          element(:"tns:IznosN", item.amount)
        ])
      end)

    elements ++ [element(:"tns:Naknade", fee_elements)]
  end

  defp maybe_add_element(elements, _name, nil), do: elements

  defp maybe_add_element(elements, name, value) do
    elements ++ [element(name, value)]
  end
end
