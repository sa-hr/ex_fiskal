defmodule ExFiskal.RequestXML do
  import XmlBuilder

  alias ExFiskal.{Cryptography, CertificateData}

  def process_request!(doc, %CertificateData{} = certificate_data) do
    request = wrap_in_request_envelope(doc)
    xml_string = canonicalize!(request)
    digest = calculate_digest(xml_string)
    signature_xml = prepare_for_signing(digest)
    signature = build_signature!(signature_xml, certificate_data)

    wrap_in_soap_envelope(xml_string, signature)
  end

  defp build_signature!(signed_element, certificate_data) do
    signature = Cryptography.sign_string!(signed_element, certificate_data.key)

    signature_xml =
      element(
        :Signature,
        %{"xmlns" => "http://www.w3.org/2000/09/xmldsig#"},
        [
          "%%%REPLACETOKEN%%%",
          element(:SignatureValue, signature),
          element(:KeyInfo, [
            element(:X509Data, [
              element(:X509Certificate, certificate_data.encoded_certificate),
              element(:X509IssuerSerial, [
                element(:X509IssuerName, certificate_data.issuer_name),
                element(:X509SerialNumber, certificate_data.issuer_serial_number)
              ])
            ])
          ])
        ]
      )
      |> generate()

    String.replace(signature_xml, "%%%REPLACETOKEN%%%", signed_element)
  end

  defp canonicalize!(doc) do
    xml = doc |> generate() |> to_charlist()
    {xml_tuples, _} = :xmerl_scan.string(xml, namespace_conformant: true, document: true)
    {:ok, result} = XmerlC14n.canonicalize(xml_tuples)
    result
  end

  defp calculate_digest(xml_string) do
    :crypto.hash(:sha, xml_string) |> Base.encode64()
  end

  defp prepare_for_signing(digest) do
    element(
      :SignedInfo,
      %{"xmlns" => "http://www.w3.org/2000/09/xmldsig#"},
      [
        element(
          :CanonicalizationMethod,
          %{"Algorithm" => "http://www.w3.org/2001/10/xml-exc-c14n#"}
        ),
        element(
          :SignatureMethod,
          %{"Algorithm" => "http://www.w3.org/2000/09/xmldsig#rsa-sha1"}
        ),
        element(
          :Reference,
          %{"URI" => "#RacunZahtjev"},
          [
            element(:Transforms, [
              element(
                :Transform,
                %{"Algorithm" => "http://www.w3.org/2000/09/xmldsig#enveloped-signature"}
              ),
              element(
                :Transform,
                %{"Algorithm" => "http://www.w3.org/2001/10/xml-exc-c14n#"}
              )
            ]),
            element(
              :DigestMethod,
              %{"Algorithm" => "http://www.w3.org/2000/09/xmldsig#sha1"}
            ),
            element(:DigestValue, digest)
          ]
        )
      ]
    )
    |> canonicalize!()
  end

  defp wrap_in_request_envelope(elements) do
    element(
      :"tns:RacunZahtjev",
      %{
        "xmlns:tns" => "http://www.apis-it.hr/fin/2012/types/f73",
        "Id" => "RacunZahtjev"
      },
      elements
    )
  end

  defp wrap_in_soap_envelope(doc, signature) do
    doc = String.replace(doc, "</tns:RacunZahtjev>", "")
    doc = doc <> "#{signature}</tns:RacunZahtjev>"

    envelope =
      document([
        element(
          :"soapenv:Envelope",
          %{
            "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/"
          },
          [
            element(:"soapenv:Body", nil, ["%%%REPLACETOKEN%%%"])
          ]
        )
      ])
      |> generate()

    String.replace(envelope, "%%%REPLACETOKEN%%%", doc)
  end
end
