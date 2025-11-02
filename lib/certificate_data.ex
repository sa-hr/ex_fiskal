defmodule ExFiskal.CertificateData do
  defstruct [
    :key,
    :certificate,
    :encoded_certificate,
    :issuer_name,
    :issuer_serial_number,
    :subject_name
  ]

  def new(%{
        "key" => key,
        "certificate" => certificate,
        "encoded_certificate" => encoded_certificate,
        "issuer_name" => issuer_name,
        "issuer_serial_number" => issuer_serial_number,
        "subject_name" => subject_name
      }) do
    %__MODULE__{
      key: key,
      certificate: certificate,
      encoded_certificate: encoded_certificate,
      issuer_name: issuer_name,
      issuer_serial_number: issuer_serial_number,
      subject_name: subject_name
    }
  end

  def new(%{
        key: key,
        certificate: certificate,
        encoded_certificate: encoded_certificate,
        issuer_name: issuer_name,
        issuer_serial_number: issuer_serial_number,
        subject_name: subject_name
      }) do
    %__MODULE__{
      key: key,
      certificate: certificate,
      encoded_certificate: encoded_certificate,
      issuer_name: issuer_name,
      issuer_serial_number: issuer_serial_number,
      subject_name: subject_name
    }
  end
end
