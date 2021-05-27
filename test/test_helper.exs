# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

Application.put_env(:bmp3xx, :transport_module, BMP3XX.MockI2C)
Mox.defmock(BMP3XX.MockI2C, for: BMP3XX.Transport)
Mox.stub_with(BMP3XX.MockI2C, BMP3XX.Transport.I2C.Stub)

ExUnit.start()
