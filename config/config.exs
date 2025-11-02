import Config

config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "project"
  version = "0.0.0"
  requires-python = "==3.13.*"
  dependencies = [
    "cryptography==46.0.3"
  ]
  """
