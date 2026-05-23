{
  # keep-sorted start
  hermes-agent = import ./hermes-agent.nix;
  postgresql = import ./postgresql.nix;
  rabbitmq = import ./rabbitmq.nix;
  # keep-sorted end
}
