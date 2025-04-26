{ config, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = config.ports.node-exporter;
    enabledCollectors = [
      "systemd"
      "logind"
    ];
  };
}
