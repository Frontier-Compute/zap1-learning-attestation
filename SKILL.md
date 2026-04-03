# ZAP1 Learning Attestation

**ClawHub Skill** - Attest self-improving-agent learnings to Zcash.

Every correction, error, and feature request gets a cryptographic proof on-chain. When the agent learns something, that fact is permanently recorded in the ZAP1 Merkle tree and anchored to Zcash mainnet.

## What This Skill Does

When a file is written to `.learnings/`, this skill:

1. SHA256-hashes the file content
2. Posts an `AGENT_ACTION` event to the ZAP1 API with `action_type=LEARNING`
3. Returns a `leaf_hash` - the permanent proof of that learning

The `leaf_hash` links to a Merkle proof anchored to Zcash. Anyone can verify `GET /verify/{leaf_hash}` to confirm when the agent recorded that entry.

## Trigger

PostToolUse hook - fires after any tool write that touches `.learnings/`.

In your `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/zap1-learning-attestation/scripts/hook-dispatch.sh"
          }
        ]
      }
    ]
  }
}
```

The `.learnings/` path check is built into `attest-learning.sh` - non-matching writes exit silently. `hook-dispatch.sh` reads the file path from the hook's stdin JSON and calls `attest-learning.sh`.

## Required Environment Variables

| Variable | Description |
|---|---|
| `ZAP1_API_KEY` | API key from pay.frontiercompute.io |
| `ZAP1_AGENT_ID` | Identifier for this agent instance |
| `ZAP1_API_URL` | Defaults to `https://pay.frontiercompute.io` |

## Output

The script prints:

```
[ZAP1] Attested: <filename>
[ZAP1] content_hash: <64-char hex>
[ZAP1] leaf_hash: <64-char hex>
[ZAP1] Verify: https://pay.frontiercompute.io/verify/<leaf_hash>
```

The agent sees this in its tool output and can include the `leaf_hash` in subsequent responses as a proof reference.

## Protocol

Uses ZAP1 `AGENT_ACTION` event type (memo type `0x42`). Fields:

- `agent_id` - set via `ZAP1_AGENT_ID`
- `action_type` - always `LEARNING`
- `input_hash` - SHA256 of the learning file content
- `output_hash` - same as `input_hash` (this is a record, not a transform)

The leaf is inserted into the ZAP1 Merkle tree and the next anchor cycle commits it to Zcash mainnet.
