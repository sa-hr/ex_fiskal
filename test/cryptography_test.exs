defmodule ExFiskal.CryptographyTest do
  use ExUnit.Case

  alias ExFiskal.Cryptography
  alias ExFiskal.CertificateData

  describe "extract_certificate_data!/2" do
    test "extracts certificate data from valid p12 file" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert %CertificateData{
               key:
                 "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDPwSD4cVDoeIKk\nYR3/Urpi8nZrFkvCHyb46TwKmWwP62mO9P3QHC8Rd8/pa8cW1bjZwhhDuLvoIaRl\npJjQcFBaBl4l40eO18tWTzUg2HYt0Qa9mKn/ORVb2fhPo4lROYacXFhn32PFbT+z\njUKhTjGlRqCBQr0BCBnDWKX0GVI/eJup0DpUHEUfxpAihotIDToQO9lZZyviZH2n\nx7RklqLdr6f2rzBoUYjhlKqCO4vL6Rz9MXc1q+pLnVDafbTbyI837qeHmPliLqjk\n7snsc70/fn/2Ycg1WKaXylKCP9mjFRBpN//5vVSjQUMEtiAVnBH1eFzA5AzJTD+0\n4BmSSedBAgMBAAECggEAIM3UcxY6xHJJjUNpH/3ZQLLF6v56w4dKuTvkB00WveQZ\n51ZHgNBVHZ4m/gBOz+Flo5CyZyMTcexkpR4FI8h65N7OMo+oJrsWjXrKn0npTdkM\nW5dFpG9IMELYeAQRCc/FBwnNIHMAByugcYKpFjJJbtjvkr7N0Yy3ZgZ93G9mcsSY\nj285PTyMVYAQAxgg2k2XpYDbXkqUr8+Jz+oVkV7ZKXvqpd+ABRZs5QcpOiHeK6eL\n6eAUGipHB7lDIPvRCEZ0IEZCzqnrlBRuQeCpQ6vhLGY3qJ5aj/kW0g90Blsu24OR\nqMt0B1smPfX1ln8SXsFfsdWdW4bOFBNkT7bTRW8dPwKBgQD8LtNBIYsxvh6JbORr\ngWxdLKoGYcFhyltUiWexzrpS/kFyhVHHbWzf3jgl9pRF0ndu+oZDlfW7+MWd5pZw\n9R3IOd3dzG2goqNfgxd0SC8It8r+82XwELrij3A3EBiescUbhXAxi00thAPBM4w3\na5Eye3FKoT11Bs7FovKPE4TOqwKBgQDS5iYs73KaqeusgAmfs4kcX9DBFO5k1Tkx\nHVJ0KF152af8n4+KooYcAgc7q6Rt3F/3E/teL1Ooj8AOfwwlZm0eXBVnZIIaddjq\nojejgsTF340KyAPCpTEbL/sPIGt0SUB9mmxjkbLcxGcwyV34d+D2dkWli9MqSjYe\n82J14rVxwwKBgAHkqBlZEx5wevI1KxHTiui4KR6bJUSCrGTaEzk2gBeXaQ5fCdoh\nbCvSE0HVtA9CITtoDhH70jhzCajBzmdSr8KNDKlZm4kVL3zMEyUAVboPBysa0K0Y\nsw54XTNMn6KxWvV17v2wOggZcZ3FsUvJNvHWE2eoBjoWrv601nVUhC65AoGBAJSa\nzT2Of5+RqdnD4oQgerV+olbbC9wLDqCX+7iTlMI+Zwsv13IlcQAdQcF/AX7T8N7l\nupK0IGu+1uKgDQvxb2QcGIzhGnfQoEc8hJ33j/WpvvVg2J13zvFMTshq3Kx0zTdz\n73n9eR3sWpXa3hctSVwBHLQ4oVPENPx8HN3aIGYHAoGBAK301frfoVHT/G3D5DMz\n+vfUFFMIS4haCTlGWHXoEXAHayUIzFUR0dEjmxV8vBg2fcZS25kDpj9k79EDsCGp\nxpds7BPfwQaf/dfEk52qkeeNJoNb4/Pv5SMNryY3zdUSQBF1lggDb8NwPFS8apuC\nC0TMBPb/BLBqbs0HO2+OpbnE\n-----END PRIVATE KEY-----\n",
               certificate:
                 "-----BEGIN CERTIFICATE-----\nMIIDRTCCAi2gAwIBAgIUNYN520wgWwKhxANL9RKzHrn/dfkwDQYJKoZIhvcNAQEL\nBQAwMjENMAsGA1UEAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNV\nBAYTAlVTMB4XDTI0MTIyOTEyMTUxNloXDTI1MTIyOTEyMTUxNlowMjENMAsGA1UE\nAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNVBAYTAlVTMIIBIjAN\nBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz8Eg+HFQ6HiCpGEd/1K6YvJ2axZL\nwh8m+Ok8CplsD+tpjvT90BwvEXfP6WvHFtW42cIYQ7i76CGkZaSY0HBQWgZeJeNH\njtfLVk81INh2LdEGvZip/zkVW9n4T6OJUTmGnFxYZ99jxW0/s41CoU4xpUaggUK9\nAQgZw1il9BlSP3ibqdA6VBxFH8aQIoaLSA06EDvZWWcr4mR9p8e0ZJai3a+n9q8w\naFGI4ZSqgjuLy+kc/TF3NavqS51Q2n2028iPN+6nh5j5Yi6o5O7J7HO9P35/9mHI\nNViml8pSgj/ZoxUQaTf/+b1Uo0FDBLYgFZwR9XhcwOQMyUw/tOAZkknnQQIDAQAB\no1MwUTAdBgNVHQ4EFgQUESypFouaxAv/NE2qRFdzeVe4YJ0wHwYDVR0jBBgwFoAU\nESypFouaxAv/NE2qRFdzeVe4YJ0wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B\nAQsFAAOCAQEAoutK7DUh07sphKs47kVT5c4STYtrEdVZJ3NPk+UpkXSwrTft7tzg\nArlE5Y+1acoNNz1p852eWuqUQIBxIIpfaLYE8GSj+F5uaVj9jPBGwXpxArZm3RyQ\nZupEL4TC8S0h/dy++3cVCpj7TdpEgwWJij2vUUdecZ2aAkCXGs36cWA5b0+82qVj\nputJs9h/9H6EgQhbjb+MB1VTG8UQjin4yry20Eti7LPQImTvCfKcMM7BtncU0O47\n4z2cNOYdYYezrEgb43tODFjy9S/ekpLm7ND8C4Yge1MqJrEdBkux1Zk9L036Mh7a\nmvMMfr0zx982/5nVfZ9w4TD0dYapi0Uy7A==\n-----END CERTIFICATE-----\n",
               encoded_certificate:
                 "MIIDRTCCAi2gAwIBAgIUNYN520wgWwKhxANL9RKzHrn/dfkwDQYJKoZIhvcNAQELBQAwMjENMAsGA1UEAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNVBAYTAlVTMB4XDTI0MTIyOTEyMTUxNloXDTI1MTIyOTEyMTUxNlowMjENMAsGA1UEAwwEVGVzdDEUMBIGA1UECgwLWW91ckNvbXBhbnkxCzAJBgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz8Eg+HFQ6HiCpGEd/1K6YvJ2axZLwh8m+Ok8CplsD+tpjvT90BwvEXfP6WvHFtW42cIYQ7i76CGkZaSY0HBQWgZeJeNHjtfLVk81INh2LdEGvZip/zkVW9n4T6OJUTmGnFxYZ99jxW0/s41CoU4xpUaggUK9AQgZw1il9BlSP3ibqdA6VBxFH8aQIoaLSA06EDvZWWcr4mR9p8e0ZJai3a+n9q8waFGI4ZSqgjuLy+kc/TF3NavqS51Q2n2028iPN+6nh5j5Yi6o5O7J7HO9P35/9mHINViml8pSgj/ZoxUQaTf/+b1Uo0FDBLYgFZwR9XhcwOQMyUw/tOAZkknnQQIDAQABo1MwUTAdBgNVHQ4EFgQUESypFouaxAv/NE2qRFdzeVe4YJ0wHwYDVR0jBBgwFoAUESypFouaxAv/NE2qRFdzeVe4YJ0wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAoutK7DUh07sphKs47kVT5c4STYtrEdVZJ3NPk+UpkXSwrTft7tzgArlE5Y+1acoNNz1p852eWuqUQIBxIIpfaLYE8GSj+F5uaVj9jPBGwXpxArZm3RyQZupEL4TC8S0h/dy++3cVCpj7TdpEgwWJij2vUUdecZ2aAkCXGs36cWA5b0+82qVjputJs9h/9H6EgQhbjb+MB1VTG8UQjin4yry20Eti7LPQImTvCfKcMM7BtncU0O474z2cNOYdYYezrEgb43tODFjy9S/ekpLm7ND8C4Yge1MqJrEdBkux1Zk9L036Mh7amvMMfr0zx982/5nVfZ9w4TD0dYapi0Uy7A==",
               issuer_name: "commonName=Test,organizationName=YourCompany,countryName=US",
               issuer_serial_number: "305508523684296432178186574353373956684086474233",
               subject_name: "commonName=Test,organizationName=YourCompany,countryName=US"
             } = certificate_data
    end

    test "extracts PEM formatted private key" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.contains?(certificate_data.key, "-----BEGIN PRIVATE KEY-----")
      assert String.contains?(certificate_data.key, "-----END PRIVATE KEY-----")
    end

    test "extracts PEM formatted certificate" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.contains?(certificate_data.certificate, "-----BEGIN CERTIFICATE-----")
      assert String.contains?(certificate_data.certificate, "-----END CERTIFICATE-----")
    end

    test "extracts base64 encoded certificate" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.match?(certificate_data.encoded_certificate, ~r/^[A-Za-z0-9+\/=]+$/)
    end

    test "extracts issuer name with proper formatting" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.contains?(certificate_data.issuer_name, "=")
    end

    test "extracts subject name with proper formatting" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.contains?(certificate_data.subject_name, "=")
    end

    test "extracts serial number as string" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)

      assert String.match?(certificate_data.issuer_serial_number, ~r/^\d+$/)
    end

    test "returns consistent results for same input" do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"

      certificate_data1 = Cryptography.extract_certificate_data!(p12_binary, password)
      certificate_data2 = Cryptography.extract_certificate_data!(p12_binary, password)

      assert certificate_data1.key == certificate_data2.key
      assert certificate_data1.certificate == certificate_data2.certificate
      assert certificate_data1.encoded_certificate == certificate_data2.encoded_certificate
      assert certificate_data1.issuer_name == certificate_data2.issuer_name
      assert certificate_data1.subject_name == certificate_data2.subject_name
      assert certificate_data1.issuer_serial_number == certificate_data2.issuer_serial_number
    end
  end

  describe "sign_string!/2" do
    setup do
      p12_binary = File.read!("priv/certificates/test.p12")
      password = "ExamplePassword"
      certificate_data = Cryptography.extract_certificate_data!(p12_binary, password)
      {:ok, certificate_data: certificate_data}
    end

    test "signs a string and returns base64 encoded signature", %{
      certificate_data: certificate_data
    } do
      data = "test data to sign"

      signature = Cryptography.sign_string!(data, certificate_data.key)

      assert is_binary(signature)
      assert String.match?(signature, ~r/^[A-Za-z0-9+\/=]+$/)
    end

    test "generates consistent signature for same input", %{certificate_data: certificate_data} do
      data = "consistent test data"

      signature1 = Cryptography.sign_string!(data, certificate_data.key)
      signature2 = Cryptography.sign_string!(data, certificate_data.key)

      assert signature1 == signature2
    end

    test "generates different signatures for different inputs", %{
      certificate_data: certificate_data
    } do
      data1 = "first data string"
      data2 = "second data string"

      signature1 = Cryptography.sign_string!(data1, certificate_data.key)
      signature2 = Cryptography.sign_string!(data2, certificate_data.key)

      refute signature1 == signature2
    end

    test "signs empty string", %{certificate_data: certificate_data} do
      data = ""

      signature = Cryptography.sign_string!(data, certificate_data.key)

      assert is_binary(signature)
      assert byte_size(signature) > 0
    end

    test "signs string with special characters", %{certificate_data: certificate_data} do
      data = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"

      signature = Cryptography.sign_string!(data, certificate_data.key)

      assert is_binary(signature)
      assert String.match?(signature, ~r/^[A-Za-z0-9+\/=]+$/)
    end

    test "signs string with unicode characters", %{certificate_data: certificate_data} do
      data = "Unicode: šđčćž ŠĐČĆŽ"

      signature = Cryptography.sign_string!(data, certificate_data.key)

      assert is_binary(signature)
      assert String.match?(signature, ~r/^[A-Za-z0-9+\/=]+$/)
    end

    test "signs long string", %{certificate_data: certificate_data} do
      data = String.duplicate("long data string ", 1000)

      signature = Cryptography.sign_string!(data, certificate_data.key)

      assert is_binary(signature)
      assert String.match?(signature, ~r/^[A-Za-z0-9+\/=]+$/)
    end
  end
end
