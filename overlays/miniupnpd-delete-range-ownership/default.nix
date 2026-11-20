_final: prev: {
  miniupnpd = prev.miniupnpd.overrideAttrs (oldAttrs: {
    # `DeletePortMappingRange` deletes every client's mappings in the range, while secure mode keeps `DeletePortMapping` to the client's own
    patches =
      (oldAttrs.patches or [])
      ++ [./delete-range-ownership.patch];
  });
}
