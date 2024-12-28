defmodule ExFiskal do
  @moduledoc """
  Documentation for `ExFiskal`.
  """

  alias ExFiskal.{RequestParams, RequestTemplate}

  @doc """
  Fiscalizes the recepit taking in params and the certificate and it's password.
  """
  def fiscalize(params, _certificate, _password) do
    with {:ok, params} <- RequestParams.new(params),
         _request <- RequestTemplate.generate(params) do
      {:ok, nil}
    end
  end
end
