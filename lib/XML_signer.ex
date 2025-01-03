defmodule ExFiskal.XMLSigner do
  @moduledoc """
  Handles XML digital signature creation according to the Fiskalizacija specification.
  Implements XML-DSIG enveloped signature with RSA-SHA1 and Exclusive XML Canonicalization.
  """
  alias ExFiskal.PKCS12
  import SweetXml

  @doc """
  Signs an XML request with a digital signature using a PKCS12 certificate.
  The signature is created according to the XML-DSIG specification with enveloped transform.
  """
  def sign_request(xml_string, pkcs12_binary, password) when is_binary(xml_string) do
    with {:ok, doc} <- parse_document(xml_string),
         id <- get_document_id(doc),
         {:ok, cert_info} <- PKCS12.extract_cert_info(pkcs12_binary, password),
         {:ok, signature} <- generate_signature(doc, id, pkcs12_binary, password) do
      insert_signature(xml_string, id, signature, cert_info)
    end
  end

  defp parse_document(xml_string) do
    try do
      {:ok, parse(xml_string, namespace_conformant: true)}
    rescue
      e -> {:error, "Failed to parse XML document: #{inspect(e)}"}
    end
  end

  defp get_document_id(doc) do
    # Try to get the Id attribute from RacunZahtjev or PoslovniProstorZahtjev
    xpath(
      doc,
      ~x"(//*[local-name()='RacunZahtjev']/@Id | //*[local-name()='PoslovniProstorZahtjev']/@Id)"s
    )
  end

  defp generate_signature(doc, id, pkcs12_binary, password) do
    with {:ok, digest} <- calculate_digest(doc),
         signed_info <- create_signed_info(digest, id),
         parsed_signed_info <- parse(signed_info, namespace_conformant: true),
         {:ok, canonicalized} <- XmerlC14n.canonicalize(parsed_signed_info, exclusive: true) do
      PKCS12.sign_string(canonicalized, pkcs12_binary, password)
    end
  end

  defp calculate_digest(doc) do
    case XmerlC14n.canonicalize(doc, exclusive: true) do
      {:ok, canonical} ->
        digest =
          :crypto.hash(:sha, canonical)
          |> Base.encode64()

        {:ok, digest}

      error ->
        error
    end
  end

  defp create_signed_info(digest, id) do
    """
    <SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
      <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
      <Reference URI="##{id}">
        <Transforms>
          <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
          <Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        </Transforms>
        <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
        <DigestValue>#{digest}</DigestValue>
      </Reference>
    </SignedInfo>
    """
  end

  defp insert_signature(xml_string, id, signature_value, cert_info) do
    # Find the namespace and closing tag
    root_tag =
      cond do
        String.contains?(xml_string, "RacunZahtjev") -> "RacunZahtjev"
        String.contains?(xml_string, "PoslovniProstorZahtjev") -> "PoslovniProstorZahtjev"
        true -> nil
      end

    case root_tag do
      nil ->
        {:error, "Could not determine root element"}

      tag ->
        signature_xml = create_signature_xml(signature_value, id, cert_info)

        # Insert signature before closing root tag
        result =
          xml_string
          |> String.replace(~r/<\/([^:]+:)?#{tag}>/, "#{signature_xml}</\\1#{tag}>")

        {:ok, result}
    end
  end

  defp create_signature_xml(signature_value, id, cert_info) do
    """
    <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
      #{create_signed_info(signature_value, id)}
      <SignatureValue>#{signature_value}</SignatureValue>
      <KeyInfo>
        <X509Data>
          <X509Certificate>#{cert_info.cert}</X509Certificate>
          <X509IssuerSerial>
            <X509IssuerName>#{cert_info.issuer_name}</X509IssuerName>
            <X509SerialNumber>#{cert_info.serial_number}</X509SerialNumber>
          </X509IssuerSerial>
        </X509Data>
      </KeyInfo>
    </Signature>
    """
  end
end
