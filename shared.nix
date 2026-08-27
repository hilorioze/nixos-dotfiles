{
  ignoredShellcheckRules = [
    # keep-sorted start
    "SC2016" # expressions in single quotes; intentional, referenced have no shell expansion
    "SC2086" # unquoted variables; referenced are safe
    "SC2162" # `read` without `-r`; intentional too, paths and stuff don't have backslashes
    "SC2231" # unquoted variable in `for` loop glob; see `SC2086`
    # keep-sorted end
  ];
}
