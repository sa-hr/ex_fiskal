defmodule ExFiskal.Application do
  @moduledoc """
  The ExFiskal OTP Application.

  This application starts and supervises the ExFiskal system components.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: ExFiskal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
