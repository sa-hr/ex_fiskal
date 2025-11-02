defmodule ExFiskal.Application do
  @moduledoc """
  The ExFiskal OTP Application.

  This application starts and supervises the ExFiskal system components.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Pythonx.uv_init("""
    [project]
    name = "project"
    version = "0.0.0"
    requires-python = "==3.13.0"
    dependencies = [
      "cryptography==46.0.3"
    ]
    """)

    children = []

    opts = [strategy: :one_for_one, name: ExFiskal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
