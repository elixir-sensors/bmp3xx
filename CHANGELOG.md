# Changelog

## v0.1.5

### Breaking changes
- sensor type `:bmp388` is now changed to `:bmp380` to be consistent with other sensor types

### Added
- support for BMP 2 sensors namely:
  - `:bmp180`
  - `:bmp280`
  - `:bme280`
  - `:bme680`

### Improved
- [ci] update CI
- [test] re-write test using experimental [circuit_sim](https://github.com/elixir-circuits/circuits_sim)

## v0.1.4

### Improved
* Support both v0 and v1 of `circuits_i2c`

## v0.1.3

### Improved
* Simplify I2C-related code
* Improve type spec and refactor

## v0.1.2

### Fixed
* Remove default gen server name (previously defaulted to `__MODULE__`)

## v0.1.1

### Improved
* Log helpful message on init
* Link to the BME388 data sheet in the Hexdoc

## v0.1.0

Initial release
