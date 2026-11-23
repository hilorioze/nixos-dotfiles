_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./sync-back-skip-runtime-cache.patch];
}
