{
  # keep-sorted start
  agentbox = import ./agentbox.nix;
  postgresql = import ./postgresql.nix;
  rabbitmq = import ./rabbitmq.nix;
  # keep-sorted end
}
