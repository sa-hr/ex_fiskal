defmodule ExFiskal.Cryptography do
  alias ExFiskal.CertificateData

  def extract_certificate_data!(certificate, password) do
    # Use Python only for PKCS12 extraction (no native Erlang support)
    {result, _globals} =
      Pythonx.eval(
        """
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.serialization import pkcs12

        private_key, certificate, _additional_certs = pkcs12.load_key_and_certificates(
          cert,
          password,
        )

        pem_private_key = private_key.private_bytes(
          encoding=serialization.Encoding.PEM,
          format=serialization.PrivateFormat.PKCS8,
          encryption_algorithm=serialization.NoEncryption()
        )

        pem_certificate = certificate.public_bytes(
          encoding=serialization.Encoding.PEM
        )

        {
          'key': pem_private_key,
          'certificate': pem_certificate
        }
        """,
        %{"cert" => certificate, "password" => password}
      )

    %{"key" => key, "certificate" => cert_pem} = Pythonx.decode(result)

    [{:Certificate, cert_der, :not_encrypted}] = :public_key.pem_decode(cert_pem)

    {:OTPCertificate, tbs_certificate, _signature_algorithm, _signature} =
      :public_key.pkix_decode_cert(cert_der, :otp)

    {:OTPTBSCertificate, _version, serial_number, _sig_alg, issuer, _validity, subject,
     _subject_pk_info, _issuer_unique_id, _subject_unique_id, _extensions} = tbs_certificate

    issuer_name = format_rdn_sequence(issuer)
    subject_name = format_rdn_sequence(subject)
    serial_number_string = Integer.to_string(serial_number)
    encoded_certificate = Base.encode64(cert_der)

    %{
      "key" => key,
      "certificate" => cert_pem,
      "encoded_certificate" => encoded_certificate,
      "issuer_name" => issuer_name,
      "subject_name" => subject_name,
      "issuer_serial_number" => serial_number_string
    }
    |> CertificateData.new()
  end

  defp format_rdn_sequence({:rdnSequence, rdn_sequence}) do
    rdn_sequence
    |> Enum.flat_map(fn rdn_set ->
      Enum.map(rdn_set, fn attr ->
        {oid, value} = extract_attribute(attr)
        "#{oid}=#{format_value(value)}"
      end)
    end)
    |> Enum.join(",")
  end

  defp extract_attribute({:AttributeTypeAndValue, oid, value}) do
    oid_name = oid_to_name(oid)
    {oid_name, value}
  end

  defp format_value({:utf8String, value}), do: to_string(value)
  defp format_value({:printableString, value}), do: to_string(value)
  defp format_value({:ia5String, value}), do: to_string(value)
  defp format_value({:teletexString, value}), do: to_string(value)
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value), do: to_string(value)

  defp oid_to_name({2, 5, 4, 3}), do: "commonName"
  defp oid_to_name({2, 5, 4, 6}), do: "countryName"
  defp oid_to_name({2, 5, 4, 7}), do: "localityName"
  defp oid_to_name({2, 5, 4, 8}), do: "stateOrProvinceName"
  defp oid_to_name({2, 5, 4, 10}), do: "organizationName"
  defp oid_to_name({2, 5, 4, 11}), do: "organizationalUnitName"
  defp oid_to_name({1, 2, 840, 113_549, 1, 9, 1}), do: "emailAddress"
  defp oid_to_name(oid), do: Enum.join(Tuple.to_list(oid), ".")

  def sign_string!(string, private_key_pem) do
    [{type, der_encoded, _cipher}] = :public_key.pem_decode(private_key_pem)
    private_key = :public_key.pem_entry_decode({type, der_encoded, :not_encrypted})

    signature = :public_key.sign(string, :sha, private_key)

    Base.encode64(signature)
  end
end
