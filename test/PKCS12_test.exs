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
                 "MIIDRTCCAi2gAwIBAgIUNYN520wgWwKhxANL9RKzHrn/dfkwDQYJKoZIhvcNAQELBQAwMjENMAsGA1UEAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNVBAYTAlVTMB4XDTI0MTIyOTEyMTUxNloXDTI1MTIyOTEyMTUxNlowMjENMAsGA1UEAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz8Eg+HFQ6HiCpGEd/1K6YvJ2axZLwh8m+Ok8CplsD+tpjvT90BwvEXfP6WvHFtW42cIYQ7i76CGkZaSY0HBQWgZeJeNHjtfLVk81INh2LdEGvZip/zkVW9n4T6OJUTmGnFxYZ99jxW0/s41CoU4xpUaggUK9AQgZw1il9BlSP3ibqdA6VBxFH8aQIoaLSA06EDvZWWcr4mR9p8e0ZJai3a+n9q8waFGI4ZSqgjuLy+kc/TF3NavqS51Q2n2028iPN+6nh5j5Yi6o5O7J7HO9P35/9mHINViml8pSgj/ZoxUQaTf/+b1Uo0FDBLYgFZwR9XhcwOQMyUw/tOAZkknnQQIDAQABo1MwUTAdBgNVHQ4EFgQUESypFouaxAv/NE2qRFdzeVe4YJ0wHwYDVR0jBBgwFoAUESypFouaxAv/NE2qRFdzeVe4YJ0wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAoutK7DUh07sphKs47kVT5c4STYtrEdVZJ3NPk+UpkXSwrTft7tzgArlE5Y+1acoNNz1p852eWuqUQIBxIIpfaLYE8GSj+F5uaVj9jPBGwXpxArZm3RyQZupEL4TC8S0h/dy++3cVCpj7TdpEgwWJij2vUUdecZ2aAkCXGs36cWA5b0+82qVjputJs9h/9H6EgQhbjb+MB1VTG8UQjin4yry20Eti7LPQImTvCfKcMM7BtncU0O474z2cNOYdYYezrEgb43tODFjy9S/ekpLm7ND8C4Yge1MqJrEdBkux1Zk9L036Mh7amvMMfr0zx982/5nVfZ9w4TD0dYapi0Uy7A==",
               issuer_name: "issuer=CN=Test, O=YourCompany, C=US",
               issuer_serial_number: "305508523684296432178186574353373956684086474233"
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
