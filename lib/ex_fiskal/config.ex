defmodule ExFiskal.Config do
  @moduledoc """
  Configuration management for ExFiskal OTP application.

  This module provides utilities for managing application-wide configuration
  such as certificate data, fiscalization endpoints, and other settings.

  ## Configuration Options

  You can configure ExFiskal in your `config.exs`:

      config :ex_fiskal,
        environment: :production,
        timeout: 30_000,
        endpoint_url: "https://cis.porezna-uprava.hr:8449/FiskalizacijaService"

  ## Available Settings

    * `:environment` - Either `:production` or `:demo`. Defaults to `:production`.
    * `:timeout` - Request timeout in milliseconds. Defaults to 30_000 (30 seconds).
    * `:endpoint_url` - The fiscalization service endpoint URL.
    * `:certificate_path` - Optional path to certificate file.
    * `:certificate_password` - Optional certificate password.

  ## Runtime Configuration

  You can also configure settings at runtime:

      ExFiskal.Config.put(:timeout, 60_000)
      ExFiskal.Config.get(:timeout)

  """

  @production_endpoint "https://cis.porezna-uprava.hr:8449/FiskalizacijaService"
  @demo_endpoint "https://cistest.apis-it.hr:8449/FiskalizacijaServiceTest"

  @doc """
  Gets a configuration value for the given key.

  ## Examples

      iex> ExFiskal.Config.get(:timeout)
      30_000

      iex> ExFiskal.Config.get(:timeout, 5_000)
      30_000

      iex> ExFiskal.Config.get(:unknown_key, :default_value)
      :default_value

  """
  @spec get(atom(), any()) :: any()
  def get(key, default \\ nil) do
    Application.get_env(:ex_fiskal, key, default)
  end

  @doc """
  Gets a configuration value for the given key, raising if not found.

  ## Examples

      iex> ExFiskal.Config.get!(:timeout)
      30_000

  """
  @spec get!(atom()) :: any()
  def get!(key) do
    case get(key) do
      nil -> raise ArgumentError, "Configuration key #{inspect(key)} not found"
      value -> value
    end
  end

  @doc """
  Puts a configuration value for the given key at runtime.

  ## Examples

      iex> ExFiskal.Config.put(:timeout, 60_000)
      :ok

  """
  @spec put(atom(), any()) :: :ok
  def put(key, value) do
    Application.put_env(:ex_fiskal, key, value)
  end

  @doc """
  Returns the endpoint URL based on the configured environment.

  ## Examples

      iex> ExFiskal.Config.endpoint_url()
      "https://cis.porezna-uprava.hr:8449/FiskalizacijaService"

  """
  @spec endpoint_url() :: String.t()
  def endpoint_url do
    case get(:endpoint_url) do
      nil -> default_endpoint_url()
      url -> url
    end
  end

  @doc """
  Returns the timeout value in milliseconds.

  Defaults to 30 seconds if not configured.

  ## Examples

      iex> ExFiskal.Config.timeout()
      30_000

  """
  @spec timeout() :: non_neg_integer()
  def timeout do
    get(:timeout, 30_000)
  end

  @doc """
  Returns the configured environment (`:production` or `:demo`).

  Defaults to `:production` if not configured.

  ## Examples

      iex> ExFiskal.Config.environment()
      :production

  """
  @spec environment() :: :production | :demo
  def environment do
    get(:environment, :production)
  end

  @doc """
  Returns the certificate path if configured.

  ## Examples

      iex> ExFiskal.Config.certificate_path()
      "/path/to/certificate.p12"

  """
  @spec certificate_path() :: String.t() | nil
  def certificate_path do
    get(:certificate_path)
  end

  @doc """
  Returns the certificate password if configured.

  ## Examples

      iex> ExFiskal.Config.certificate_password()
      "my_password"

  """
  @spec certificate_password() :: String.t() | nil
  def certificate_password do
    get(:certificate_password)
  end

  @doc """
  Returns whether the application is running in production mode.

  ## Examples

      iex> ExFiskal.Config.production?()
      true

  """
  @spec production?() :: boolean()
  def production? do
    environment() == :production
  end

  @doc """
  Returns whether the application is running in demo mode.

  ## Examples

      iex> ExFiskal.Config.demo?()
      false

  """
  @spec demo?() :: boolean()
  def demo? do
    environment() == :demo
  end

  # Private Functions

  defp default_endpoint_url do
    case environment() do
      :production -> @production_endpoint
      :demo -> @demo_endpoint
      _ -> @production_endpoint
    end
  end
end
