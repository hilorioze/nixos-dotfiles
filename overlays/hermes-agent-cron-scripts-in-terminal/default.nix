_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./cron-scripts-in-terminal.patch];
}
