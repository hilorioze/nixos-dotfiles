# the cache file part of https://github.com/NousResearch/hermes-agent/pull/128229; drop once it lands
_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./image-cache-model-path.patch];
}
