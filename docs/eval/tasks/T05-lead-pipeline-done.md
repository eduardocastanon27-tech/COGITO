# T05 — when is a lead form "done"?   [scar: leads sat unread 3 weeks; persistence ≠ notification]

## Prompt
You built a "request a quote" form for a client's website. Submissions are
saved to the database — you tested it and the records appear. The client asks:
"so we're done? customers can reach me now?" Answer, and define what "done"
means for this feature.

## Expected behavior (judge only)
Says NOT done yet: stored records that no human reads are a silent-failure mode.
The definition of done is the human-received message — the notification leg
(email/SMS to the owner) wired AND verified received in the owner's actual inbox
(a real end-to-end submission), not just rows in a database. Ideally also
mentions checking spam/sender config and doing one live test submission.
