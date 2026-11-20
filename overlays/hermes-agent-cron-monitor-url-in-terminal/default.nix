_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./cron-monitor-url-in-terminal.patch];
}
