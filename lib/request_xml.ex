defmodule ExFiskal.RequestXML do
  import XmlBuilder

  alias ExFiskal.PKCS12

  def process_request(doc, pkcs12_binary, password) do
    request = wrap_in_request_envelope(doc)

    with {:ok, xml_string} <- canonicalize(request),
         {:ok, digest} <- calculate_digest(xml_string),
         {:ok, signature_xml} <- prepare_for_signing(digest),
         {:ok, signature} <- build_signature(signature_xml, pkcs12_binary, password) do
      request = wrap_in_soap_envelope(xml_string, signature)

      {:ok, request}
    end
  end

  defp build_signature(signed_element, pkcs12_binary, password) do
    with {:ok, signature} <- PKCS12.sign_string(signed_element, pkcs12_binary, password),
         {:ok, cert_info} <- PKCS12.extract_cert_info(pkcs12_binary, password) do
      signature_xml =
        element(
          :Signature,
          %{"xmlns" => "http://www.w3.org/2000/09/xmldsig#"},
          [
            "%%%REPLACETOKEN%%%",
            element(:SignatureValue, signature),
            element(:KeyInfo, [
              element(:X509Data, [
                element(:X509Certificate, cert_info.cert),
                element(:X509IssuerSerial, [
                  element(:X509IssuerName, cert_info.issuer_name),
                  element(:X509SerialNumber, cert_info.issuer_serial_number)
                ])
              ])
            ])
          ]
        )
        |> generate()

      signature_xml = String.replace(signature_xml, "%%%REPLACETOKEN%%%", signed_element)

      {:ok, signature_xml}
    end
  end

  defp canonicalize(doc) do
    xml = doc |> generate() |> to_charlist()

    with {xml_tuples, _} <- :xmerl_scan.string(xml, namespace_conformant: true, document: true) do
      XmerlC14n.canonicalize(xml_tuples)
    end
  end

  defp calculate_digest(xml_string) do
    result = :crypto.hash(:sha, xml_string) |> Base.encode64()
    {:ok, result}
  rescue
    _error -> {:error, "Digest calcualtion failed"}
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
    |> canonicalize()
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
