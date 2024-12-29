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
      assert {:error, _} = PKCS12.sign_string("hello world", "invalid binary", @valid_password)
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
      assert {:error, _} = PKCS12.parse_data("invalid binary", @valid_password)
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
      assert {:error, _} = PKCS12.extract_key("invalid binary", @valid_password)
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
      assert {:error, _} = PKCS12.extract_certs("invalid binary", @valid_password)
    end
  end
end
