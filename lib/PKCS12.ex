defmodule ExFiskal.PKCS12 do
  @moduledoc """
  Handles PKCS12 certificate operations including parsing, key extraction, and signing.
  All functions accept binary data instead of file paths.
  """

  @doc """
  Signs a string using the private key from the PKCS12 binary data.
  Returns the base64-encoded signature.
  """
  def sign_string(string, pkcs12_binary, password) do
    with {:ok, key} <- extract_key(pkcs12_binary, password),
         {:ok, signature} <- sign_with_key(string, key) do
      {:ok, signature}
    end
  end

  @doc """
  Parses PKCS12 binary data and returns its contents.
  """
  def parse_data(pkcs12_binary, password) do
    with {:ok, tmp_path} <- write_temp_pkcs12(pkcs12_binary),
         result <- do_parse(tmp_path, password) do
      cleanup_temp_file(tmp_path)
      result
    end
  end

  @doc """
  Extracts the private key from PKCS12 binary data.
  """
  def extract_key(pkcs12_binary, password) do
    with {:ok, tmp_path} <- write_temp_pkcs12(pkcs12_binary),
         result <- do_extract_key(tmp_path, password) do
      cleanup_temp_file(tmp_path)
      result
    end
  end

  @doc """
  Extracts certificates from PKCS12 binary data.
  """
  def extract_certs(pkcs12_binary, password) do
    with {:ok, tmp_path} <- write_temp_pkcs12(pkcs12_binary),
         result <- do_extract_certs(tmp_path, password) do
      cleanup_temp_file(tmp_path)
      result
    end
  end

  @doc """
  Returns the current OpenSSL version installed on the system.
  """
  def get_openssl_version do
    case System.cmd("openssl", ["version"], stderr_to_stdout: true) do
      {version, 0} -> {:ok, version}
      {error, _code} -> {:error, error}
    end
  end

  defp do_parse(path, password) do
    # First try with legacy algorithms enabled
    legacy_args = [
      "pkcs12",
      "-in",
      path,
      "-nodes",
      "-passin",
      "pass:#{password}",
      "-legacy"
    ]

    # Try first with legacy support
    case System.cmd("openssl", legacy_args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      # If legacy attempt fails, try without legacy flag
      {_error, _code} ->
        standard_args = [
          "pkcs12",
          "-in",
          path,
          "-nodes",
          "-passin",
          "pass:#{password}"
        ]

        case System.cmd("openssl", standard_args, stderr_to_stdout: true) do
          {output, 0} -> {:ok, output}
          {error, _code} -> {:error, error}
        end
    end
  end

  defp do_extract_key(path, password) do
    legacy_args = [
      "pkcs12",
      "-in",
      path,
      "-nodes",
      "-nocerts",
      "-passin",
      "pass:#{password}",
      "-legacy"
    ]

    case System.cmd("openssl", legacy_args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {_error, _code} ->
        standard_args = [
          "pkcs12",
          "-in",
          path,
          "-nodes",
          "-nocerts",
          "-passin",
          "pass:#{password}"
        ]

        case System.cmd("openssl", standard_args, stderr_to_stdout: true) do
          {output, 0} -> {:ok, output}
          {error, _code} -> {:error, error}
        end
    end
  end

  defp do_extract_certs(path, password) do
    legacy_args = [
      "pkcs12",
      "-in",
      path,
      "-nodes",
      "-nokeys",
      "-passin",
      "pass:#{password}",
      "-legacy"
    ]

    case System.cmd("openssl", legacy_args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {_error, _code} ->
        standard_args = [
          "pkcs12",
          "-in",
          path,
          "-nodes",
          "-nokeys",
          "-passin",
          "pass:#{password}"
        ]

        case System.cmd("openssl", standard_args, stderr_to_stdout: true) do
          {output, 0} -> {:ok, output}
          {error, _code} -> {:error, error}
        end
    end
  end

  defp sign_with_key(string, key_content) do
    with {:ok, key_file} <- write_temp_file(key_content, "key"),
         {:ok, input_file} <- write_temp_file(string, "input") do
      args = [
        "dgst",
        "-sha1",
        "-sign",
        key_file,
        "-binary",
        input_file
      ]

      result =
        case System.cmd("openssl", args, stderr_to_stdout: true) do
          {signature, 0} -> {:ok, Base.encode64(signature)}
          {error, _code} -> {:error, "Signing failed: #{error}"}
        end

      cleanup_temp_file(key_file)
      cleanup_temp_file(input_file)
      result
    end
  end

  defp write_temp_pkcs12(binary_data) do
    write_temp_file(binary_data, "pkcs12")
  end

  defp write_temp_file(content, prefix) do
    tmp_path =
      Path.join(System.tmp_dir(), "#{prefix}_#{:crypto.strong_rand_bytes(8) |> Base.encode16()}")

    case File.write(tmp_path, content) do
      :ok -> {:ok, tmp_path}
      {:error, reason} -> {:error, "Failed to write temporary #{prefix} file: #{reason}"}
    end
  end

  defp cleanup_temp_file(path) do
    File.rm(path)
  end
end
