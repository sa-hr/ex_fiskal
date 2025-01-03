defmodule ExFiskal.PKCS12Test do
  use ExUnit.Case
  alias ExFiskal.PKCS12

  @valid_password "ExamplePassword"
  @invalid_password "IncorrectPassword"
  @test_cert_path "priv/certificates/test.p12"

  setup do
    pkcs12_binary = File.read!(@test_cert_path)
    {:ok, pkcs12_binary: pkcs12_binary}
  end

  describe "sign_string/3" do
    test "signs a string using a demo certificate", %{pkcs12_binary: pkcs12_binary} do
      assert {:ok, signed} = PKCS12.sign_string("hello world", pkcs12_binary, @valid_password)
      assert is_binary(signed)
      assert String.length(signed) > 0
      assert {:ok, _decoded} = Base.decode64(signed)

      assert signed ==
               "mKwn9/ByY/ht7K1x7rpSRsfdG0+cX8qpMB17UnkxiQvhfp4i3AjjexzqmbUgE3sh51uA85fDrwtXruGHJK+2gHBvNHPzovDYNvrv208rklyt2QHCDga6v35m0hbpWAfrLFECgIH6CpFC0XaLvrq7tlW1XPnacB3XOoOjqBGR7RlQHW7sefeO6NXmm5e+MO6MHVWiS8PuB5jeF6Koz88HYO+BTwqvibKMZXbq4N5xJp8qjNl1TmTTGTnlVM9aHrx1SVVzbrZanWHLHCPoe2OcgrXbiSoG5nCa3Rbf4xR0jP+RiXnuiQxfRXBBkmf3TvcAFSZoYjazVS9d3Axdbq8/3w=="
    end

    test "returns an error on wrong password", %{pkcs12_binary: pkcs12_binary} do
      assert {:error, error} = PKCS12.sign_string("hello world", pkcs12_binary, @invalid_password)
      assert String.contains?(error, "Mac verify error")
    end

    test "handles invalid binary data" do
      assert {:error, error} =
               PKCS12.sign_string("hello world", "invalid binary", @valid_password)

      assert String.contains?(error, "asn1 encoding routines")
      assert String.contains?(error, "not enough data")
    end
  end

  describe "parse_data/2" do
    test "successfully parses valid PKCS12 data", %{pkcs12_binary: pkcs12_binary} do
      assert {:ok, output} = PKCS12.parse_data(pkcs12_binary, @valid_password)
      assert String.contains?(output, "BEGIN PRIVATE KEY")
      assert String.contains?(output, "BEGIN CERTIFICATE")
    end

    test "returns error for invalid password", %{pkcs12_binary: pkcs12_binary} do
      assert {:error, error} = PKCS12.parse_data(pkcs12_binary, @invalid_password)
      assert String.contains?(error, "Mac verify error")
    end

    test "handles invalid binary data" do
      assert {:error, error} = PKCS12.parse_data("invalid binary", @valid_password)
      assert String.contains?(error, "asn1 encoding routines")
      assert String.contains?(error, "not enough data")
    end
  end

  describe "extract_key/2" do
    test "successfully extracts private key", %{pkcs12_binary: pkcs12_binary} do
      assert {:ok, key} = PKCS12.extract_key(pkcs12_binary, @valid_password)
      assert String.contains?(key, "BEGIN PRIVATE KEY")
      assert String.contains?(key, "END PRIVATE KEY")
    end

    test "returns error for invalid password", %{pkcs12_binary: pkcs12_binary} do
      assert {:error, error} = PKCS12.extract_key(pkcs12_binary, @invalid_password)
      assert String.contains?(error, "Mac verify error")
    end

    test "handles invalid binary data" do
      assert {:error, error} = PKCS12.extract_key("invalid binary", @valid_password)
      assert String.contains?(error, "asn1 encoding routines")
      assert String.contains?(error, "not enough data")
    end
  end

  describe "extract_certs/2" do
    test "successfully extracts certificates", %{pkcs12_binary: pkcs12_binary} do
      assert {:ok, certs} = PKCS12.extract_certs(pkcs12_binary, @valid_password)
      assert String.contains?(certs, "BEGIN CERTIFICATE")
      assert String.contains?(certs, "END CERTIFICATE")
      refute String.contains?(certs, "PRIVATE KEY")
    end

    test "returns error for invalid password", %{pkcs12_binary: pkcs12_binary} do
      assert {:error, error} = PKCS12.extract_certs(pkcs12_binary, @invalid_password)
      assert String.contains?(error, "Mac verify error")
    end

    test "handles invalid binary data" do
      assert {:error, error} = PKCS12.extract_certs("invalid binary", @valid_password)
      assert String.contains?(error, "asn1 encoding routines")
      assert String.contains?(error, "not enough data")
    end
  end

  describe "extract_cert_info/2" do
    test "successfully extracts certificate information", %{pkcs12_binary: pkcs12_binary} do
      assert {:ok, cert_info} = PKCS12.extract_cert_info(pkcs12_binary, @valid_password)

      assert cert_info == %{
               cert:
                 "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",
               issuer_name: "issuer=CN=Test, O=YourCompany, C=US",
               serial_number: "358379DB4C205B02A1C4034BF512B31EB9FF75F9"
             }
    end

    test "returns error for invalid password", %{pkcs12_binary: pkcs12_binary} do
      assert {:error, error} = PKCS12.extract_cert_info(pkcs12_binary, @invalid_password)
      assert String.contains?(error, "Mac verify error")
    end

    test "handles invalid binary data" do
      assert {:error, error} = PKCS12.extract_cert_info("invalid binary", @valid_password)
      assert String.contains?(error, "asn1 encoding routines")
      assert String.contains?(error, "not enough data")
    end
  end
end
