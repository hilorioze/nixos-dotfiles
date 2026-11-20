# the ssh part of https://github.com/NousResearch/hermes-agent/pull/129667; drop once it lands
_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./ssh-remote-kill.patch];
}
