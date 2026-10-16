{
  ignoredFlake8Rules = [
    "E501" # line too long; long lines are intentional
  ];

  ignoredShellcheckRules = [
    # keep-sorted start
    "SC2016" # expressions in single quotes; intentional, the quoted text is not meant to expand
    "SC2046" # unquoted command substitution; intentional, the substituted output is a single word
    "SC2086" # unquoted variables; the referenced ones are safe
    "SC2162" # `read` without `-r`; intentional too, paths and stuff don't have backslashes
    "SC2231" # unquoted variable in `for` loop glob; see `SC2086`
    # keep-sorted end
  ];
}
