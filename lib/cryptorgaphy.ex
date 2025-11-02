defmodule ExFiskal.Cryptorgaphy do
  alias ExFiskal.CertificateData

  def extract_certificate_data!(certificate, password) do
    {result, _globals} =
      Pythonx.eval(
        """
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.serialization import pkcs12
        import base64

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
        der_certificate = certificate.public_bytes(serialization.Encoding.DER)

        issuer_parts = []
        for attribute in certificate.issuer:
          issuer_parts.append(f"{attribute.oid._name}={attribute.value}")
        issuer_name = ",".join(issuer_parts)

        subject_parts = []
        for attribute in certificate.subject:
          subject_parts.append(f"{attribute.oid._name}={attribute.value}")
        subject_name = ",".join(subject_parts)

        serial_number = str(certificate.serial_number)

        {
          'key': pem_private_key,
          'certificate': pem_certificate,
          'encoded_certificate': base64.b64encode(der_certificate),
          'issuer_name': issuer_name,
          'subject_name': subject_name,
          'issuer_serial_number': serial_number
        }
        """,
        %{"cert" => certificate, "password" => password}
      )

    result
    |> Pythonx.decode()
    |> CertificateData.new()
  end

  def sign_string!(string, private_key_pem) do
    {result, _globals} =
      Pythonx.eval(
        """
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import padding
        import base64

        private_key = serialization.load_pem_private_key(
          private_key_pem,
          password=None
        )

        signature = private_key.sign(
          data,
          padding.PKCS1v15(),
          hashes.SHA1()
        )

        base64.b64encode(signature)
        """,
        %{"private_key_pem" => private_key_pem, "data" => string}
      )

    Pythonx.decode(result)
  end
end
