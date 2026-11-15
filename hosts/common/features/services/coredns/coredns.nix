{
  services.coredns = {
    enable = true;

    config = ''
      (upstream) {
        forward . 1.1.1.1 1.0.0.1 # chosen as the best-performing resolvers

        cache
      }
    '';
  };
}
