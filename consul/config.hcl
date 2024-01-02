consul {
  retry {
    enabled = true
    attempts = 3
    backoff = "50ms"
    max_backoff = "1m"
  }
}

log_level = "info"
wait = "1s:45s"
pid_file = "/var/run/consul-template.pid"

deduplicate {
  enabled = true
  prefix = "consul-template/dedup/"
}