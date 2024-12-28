defmodule ExFiskal.RequestTemplate do
  def generate(params) do
    params = set_defaults(params)

    """
    <tns:RacunZahtjev xmlns:tns="http://www.apis-it.hr/fin/2012/types/f73" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <tns:Zaglavlje>
        <tns:IdPoruke>#{params.message_id}</tns:IdPoruke>
        <tns:DatumVrijeme>#{params.datetime}</tns:DatumVrijeme>
      </tns:Zaglavlje>
      <tns:Racun>
        <tns:Oib>#{params.tax_number}</tns:Oib>
        <tns:USustPdv>#{params.in_vat_system}</tns:USustPdv>
        <tns:DatVrijeme>#{params.invoice_datetime}</tns:DatVrijeme>
        <tns:OznSlijed>#{params.sequence_mark}</tns:OznSlijed>
        <tns:BrRac>
          <tns:BrOznRac>#{params.invoice_number}</tns:BrOznRac>
          <tns:OznPosPr>#{params.business_unit}</tns:OznPosPr>
          <tns:OznNapUr>#{params.device_number}</tns:OznNapUr>
        </tns:BrRac>
        #{maybe_generate_vat(params.vat)}
        #{maybe_generate_consumption_tax(params.consumption_tax)}
        #{maybe_generate_other_taxes(params.other_taxes)}
        #{if params.vat_free_amount, do: "<tns:IznosOslobPdv>#{params.vat_free_amount}</tns:IznosOslobPdv>"}
        #{if params.margin_amount, do: "<tns:IznosMarza>#{params.margin_amount}</tns:IznosMarza>"}
        #{maybe_generate_fees(params.fees)}
        <tns:IznosUkupno>#{params.total_amount}</tns:IznosUkupno>
        <tns:NacinPlac>#{params.payment_method}</tns:NacinPlac>
        <tns:OibOper>#{params.operator_tax_number}</tns:OibOper>
        <tns:ZastKod>#{params.security_code}</tns:ZastKod>
        <tns:NakDost>#{params.subsequent_delivery}</tns:NakDost>
        #{if params.paragon_number, do: "<tns:ParagonBrRac>#{params.paragon_number}</tns:ParagonBrRac>"}
        #{if params.special_purpose, do: "<tns:SpecNamj>#{params.special_purpose}</tns:SpecNamj>"}
      </tns:Racun>
    </tns:RacunZahtjev>
    """
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
        paragon_number: nil,
        special_purpose: nil
      },
      params
    )
  end

  defp maybe_generate_vat(nil), do: ""
  defp maybe_generate_vat(vat_items) when length(vat_items) == 0, do: ""

  defp maybe_generate_vat(vat_items) do
    """
        <tns:Pdv>
          #{generate_vat_items(vat_items)}
        </tns:Pdv>
    """
  end

  defp maybe_generate_consumption_tax(nil), do: ""
  defp maybe_generate_consumption_tax(items) when length(items) == 0, do: ""

  defp maybe_generate_consumption_tax(tax_items) do
    """
        <tns:Pnp>
          #{generate_consumption_tax_items(tax_items)}
        </tns:Pnp>
    """
  end

  defp maybe_generate_other_taxes(nil), do: ""
  defp maybe_generate_other_taxes(items) when length(items) == 0, do: ""

  defp maybe_generate_other_taxes(tax_items) do
    """
        <tns:OstaliPor>
          #{generate_other_taxes_items(tax_items)}
        </tns:OstaliPor>
    """
  end

  defp maybe_generate_fees(nil), do: ""
  defp maybe_generate_fees(items) when length(items) == 0, do: ""

  defp maybe_generate_fees(fee_items) do
    """
        <tns:Naknade>
          #{generate_fee_items(fee_items)}
        </tns:Naknade>
    """
  end

  defp generate_vat_items(vat_items) do
    Enum.map_join(vat_items, "\n", fn item ->
      """
            <tns:Porez>
              <tns:Stopa>#{item.rate}</tns:Stopa>
              <tns:Osnovica>#{item.base}</tns:Osnovica>
              <tns:Iznos>#{item.amount}</tns:Iznos>
            </tns:Porez>
      """
    end)
  end

  defp generate_consumption_tax_items(tax_items) do
    Enum.map_join(tax_items, "\n", fn item ->
      """
            <tns:Porez>
              <tns:Stopa>#{item.rate}</tns:Stopa>
              <tns:Osnovica>#{item.base}</tns:Osnovica>
              <tns:Iznos>#{item.amount}</tns:Iznos>
            </tns:Porez>
      """
    end)
  end

  defp generate_other_taxes_items(tax_items) do
    Enum.map_join(tax_items, "\n", fn item ->
      """
            <tns:Porez>
              <tns:Naziv>#{item.name}</tns:Naziv>
              <tns:Stopa>#{item.rate}</tns:Stopa>
              <tns:Osnovica>#{item.base}</tns:Osnovica>
              <tns:Iznos>#{item.amount}</tns:Iznos>
            </tns:Porez>
      """
    end)
  end

  defp generate_fee_items(fee_items) do
    Enum.map_join(fee_items, "\n", fn item ->
      """
            <tns:Naknada>
              <tns:NazivN>#{item.name}</tns:NazivN>
              <tns:IznosN>#{item.amount}</tns:IznosN>
            </tns:Naknada>
      """
    end)
  end
end
