There's not much here yet, but for the time being, please use http://dlo.me/archives/2013/02/11/the-perfect-bug-report/ as a guide for filing bugs or feature enhancements.

Never close an issue through a commit that's not a merge commit. E.g., "fixes crash when viewing tags, refs #123" is OK, but "fixes crash when viewing tags, closes #123" is *not* OK.

Any time an issue is queued for fixing in a milestone, label with with "queued".

When an issue is addressed, remove the "queued" tag and add "needs changelog mention" label. In the commit message, write "added to changelog, refs #123". After a bug or enhancement has been added to the changelog, add the "give user update" label so that when the update hits the App Store, users who originally reported the issue can be notified.

If an issue is a duplicate, move the issue to the milestone where the original issue lives, label it "duplicate", but do NOT close it. Write the issue it duplicates in parenthesis. E.g., "Crash when viewing saved feeds (duplicate of #123)" where #123 is the original issue.

Use the "pinboard" or "delicious" labels if a bug or enhancement only relates to Pinboard or Delicious.
