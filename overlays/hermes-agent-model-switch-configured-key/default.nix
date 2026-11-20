_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./model-switch-configured-key.patch];
}
