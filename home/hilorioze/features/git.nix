{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "hilorioze";
        email = "me@hilorioze.com";
      };

      init.defaultBranch = "main";

      alias = {
        a = "add";
        aa = "add --all";
        c = "commit";
        cm = "commit --message";
        ca = "commit --amend";
        u = "reset --soft HEAD~1"; # undo last commit but keep changes
        d = "diff";
        dc = "diff --cached"; # show diff of staged changes
        b = "branch";
        bd = "branch --delete"; # delete local branch
        ch = "checkout";
        cb = "checkout -b"; # create and switch to new branch
        m = "merge";
        rb = "rebase";
        rbc = "rebase --continue";
        rbs = "rebase --skip";
        rba = "rebase --abort";
        rv = "revert";
        f = "fetch --all";
        fp = "fetch --all --prune"; # fetch everything and remove deleted branches
        ps = "push";
        pf = "push --force-with-lease"; # safe force push, checks remote state
        pl = "pull --rebase"; # pull with rebase instead of merge
        s = "status -sb"; # short and branch-aware status
        l = "log --oneline --graph --decorate --all";
        st = "stash";
        stl = "stash list";
        stp = "stash pop";
        sta = "stash apply"; # apply stash without deleting it
      };
    };
  };
}
