# Changelog

## [0.0.1] - 2026-01-25
### Added
- `sysinfo-device` app produces to collector.
- `collector` receives message and writes to NATS subject.
- `web-api` listens to subject, writes to database when message received.
- `web-api` exposes a REST API to interface with the time-series data. For now, this is just reading all MAC addresses.
- Build configuration, scripts, Dockerfiles et al. for all of the above.
