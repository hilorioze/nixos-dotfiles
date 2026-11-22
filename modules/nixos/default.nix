{
  # keep-sorted start
  _3proxy = import ./3proxy.nix;
  agentbox = import ./agentbox.nix;
  postgresql = import ./postgresql.nix;
  rabbitmq = import ./rabbitmq.nix;
  # keep-sorted end
}
