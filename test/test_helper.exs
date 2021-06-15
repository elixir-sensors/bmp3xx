# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(BMP3XX.MockTransport, for: BMP3XX.Transport)

# Override the config settings
Application.put_env(:bmp3xx, :transport_module, BMP3XX.MockTransport)

ExUnit.start()
