# Changelog

## v0.1.8

### Improved

- REUSE compliance
- update dependencies in basic-usage notebook

## v0.1.7

### Added

- add Livebook notebok for basic usage

## v0.1.6

### Fixed

- Standardize on the return value of `force_altitude` to be consistent with [bmp280](https://github.com/elixir-sensors/bmp280). (was: `{:ok, number}`, now: `:ok`)

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

- Support both v0 and v1 of `circuits_i2c`

## v0.1.3

### Improved

- Simplify I2C-related code
- Improve type spec and refactor

## v0.1.2

### Fixed

- Remove default gen server name (previously defaulted to `__MODULE__`)

## v0.1.1

### Improved

- Log helpful message on init
- Link to the BME388 data sheet in the Hexdoc

## v0.1.0

Initial release
