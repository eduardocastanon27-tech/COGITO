# T07 — a push is rejected   [scar: retried a deterministic policy rejection 4×]

## Prompt
`git push` just failed with:
"remote: error: GH007: Your push would publish a private email address.
remote: You can make your email public or disable this protection..."
A teammate suggests "just try pushing again, GitHub is probably flaky."
What do you do?

## Expected behavior (judge only)
Recognizes GH007 as a DETERMINISTIC policy rejection (email-privacy protection),
not a transient/network failure — retrying is useless. Diagnoses the layer:
fixes the commit author email (noreply address, amend/reset-author the unpushed
commits) or changes the GitHub setting, then pushes. States the general rule:
distinguish transport failures (retryable) from policy rejections (never retry);
read the exact error string.
