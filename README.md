# ZAP1 Learning Attestation

Verifiable continuous improvement.

Pairs with [self-improving-agent](https://github.com/pskoett/self-improving-agent) (343K downloads). Every learning, correction, and feature request the agent records gets a cryptographic proof anchored to Zcash mainnet via [ZAP1](https://pay.frontiercompute.io).

When the agent learns something, you can prove when it happened - down to the Zcash block.

## How It Works

1. Agent writes a new file to `.learnings/`
2. The PostToolUse hook fires `attest-learning.sh`
3. The script SHA256-hashes the file and POSTs to ZAP1
4. ZAP1 inserts a leaf into its Merkle tree and returns a `leaf_hash`
5. On the next anchor cycle, the root is committed to Zcash mainnet

From that point, `GET /verify/{leaf_hash}` returns a Merkle proof showing your learning was included in a Zcash-anchored root.

## Install

### Prerequisites

- [self-improving-agent](https://github.com/pskoett/self-improving-agent) installed and running
- `curl` and `sha256sum` on PATH
- A ZAP1 API key from [pay.frontiercompute.io](https://pay.frontiercompute.io)

### Step 1: Clone this repo

```bash
git clone https://github.com/Frontier-Compute/zap1-learning-attestation
cd zap1-learning-attestation
chmod +x scripts/attest-learning.sh scripts/hook-dispatch.sh
```

### Step 2: Set environment variables

```bash
export ZAP1_API_KEY=your_key_here
export ZAP1_AGENT_ID=my-agent-name
# Optional - defaults to https://pay.frontiercompute.io
export ZAP1_API_URL=https://pay.frontiercompute.io
```

Add these to your shell profile or a `.env` file sourced before the agent runs.

### Step 3: Register the ClawHub skill

Add to your Claude Code `settings.json` (usually `~/.claude/settings.json`):

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

Replace `/path/to/` with the actual clone path. The script only acts on files whose path contains `.learnings/` - other writes are silently ignored.

### Step 4: Test manually

```bash
mkdir -p /tmp/.learnings
echo "Test learning entry" > /tmp/.learnings/test.md
ZAP1_API_KEY=your_key ZAP1_AGENT_ID=test-agent \
  ./scripts/attest-learning.sh /tmp/.learnings/test.md
```

Expected output:

```
[ZAP1] Attested: test.md
[ZAP1] content_hash: <64 hex chars>
[ZAP1] leaf_hash: <64 hex chars>
[ZAP1] Verify: https://pay.frontiercompute.io/verify/<leaf_hash>
```

## Verifying a Proof

```bash
curl https://pay.frontiercompute.io/verify/{leaf_hash}/proof.json
```

Returns the full Merkle proof bundle including the Zcash transaction ID that anchors the root.

Or use the web UI: `https://pay.frontiercompute.io/verify/{leaf_hash}`

## Live Proofs

Active attestations are visible at [pay.frontiercompute.io](https://pay.frontiercompute.io). Each anchored root links to a Zcash explorer entry showing the on-chain memo.

## ZAP1 Protocol

ZAP1 is a Zcash-based attestation protocol. It uses structured shielded memos (ZIP 302) to record events in a Merkle tree. The tree root is periodically committed to Zcash mainnet by sending a shielded transaction. Anyone holding the leaf hash can verify inclusion without revealing any other leaf.

Full protocol spec: [ZAP1 on-chain protocol](https://github.com/Frontier-Compute/zap1/blob/main/ONCHAIN_PROTOCOL.md)

## Pricing

ZAP1 API keys include a leaf quota. Each attestation uses one leaf. Check your quota via the miner dashboard or contact `zk_nd3r@frontiercompute.io`.

## License

MIT - see LICENSE
