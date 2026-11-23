_final: prev: {
  hermesAgentPatches = (prev.hermesAgentPatches or []) ++ [./openai-native-web-search-chat.patch];
}
