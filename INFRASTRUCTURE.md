# Infrastructure Requirements

This document describes the external infrastructure needed for each Link Language protocol under test. Some protocols are fully P2P and need nothing; others require relay servers, homeservers, or daemon processes.

## Overview

| Protocol | Infrastructure | Self-Hosted | Public Option | Cost |
|---|---|---|---|---|
| Holochain | None | — | Public bootstrap/signal | Free |
| ActivityPub | None | — | Built into executor | Free |
| AT Protocol | PDS server | ✅ Docker | bsky.social | Minimal |
| Nostr | Relay | ✅ Docker | Public relays | Minimal |
| Matrix | Homeserver | ✅ Docker | matrix.org | Minimal |
| Solid | Pod server | ✅ Docker | solidcommunity.net | Minimal |
| IPFS | kubo daemon | ✅ Docker | Public gateways | Minimal |
| Hypercore | None | — | Hyperswarm DHT | Free |

---

## Holochain

### What's Needed
**Nothing.** Holochain uses public bootstrap and signal servers operated by the Holochain Foundation. Peers discover each other via a distributed hash table (DHT).

### Network Requirements
- **Outbound internet** on both machines (for bootstrap/signal server connections)
- **UDP/TCP** to public Holochain infrastructure
- No specific ports need to be opened inbound

### Persistence
Data is stored locally in the conductor's database. If a machine goes offline, its data persists locally and will re-sync when it reconnects to the DHT.

### Notes
- Initial peer discovery may take 10-30 seconds
- Consider increasing `SYNC_WAIT_SECONDS` for Holochain tests
- No Docker infrastructure needed

---

## ActivityPub

### What's Needed
**Nothing external.** The AD4M executor includes a built-in ActivityPub server. Both executors federate directly with each other.

### Network Requirements
- **Both executor ports must be reachable** from each other (bidirectional HTTP)
- If behind NAT, both machines need port forwarding or a shared network (LAN/Tailscale)
- Protocol: HTTP (TCP)

### Persistence
ActivityPub data is stored in the executor's data directory. Federation ensures both sides have copies.

### Notes
- The simplest protocol to test — no external dependencies
- Sync speed depends on executor-to-executor HTTP latency

---

## AT Protocol

### What's Needed
A **Personal Data Server (PDS)** — the storage backend for AT Protocol accounts and data.

### Self-Hosted (Recommended for Testing)

Docker Compose file: `infra/docker-compose.atproto.yml`

```bash
# Start PDS
docker compose -f infra/docker-compose.atproto.yml up -d

# Verify
curl http://localhost:2583/xrpc/_health
```

**Ports:**
| Port | Service | Protocol |
|---|---|---|
| 2583 | PDS HTTP API | TCP |

### Public/Cloud Option
Use [bsky.social](https://bsky.social) as the PDS, but this requires real Bluesky accounts and isn't suitable for automated testing with throwaway data.

### Network Requirements
- Both devices must be able to reach the PDS over HTTP
- If self-hosting, port 2583 must be accessible from both machines
- PDS handles DID resolution via plc.directory (needs outbound internet)

### Infrastructure Cost
**Minimal.** Single container, ~100MB RAM, negligible disk.

### Persistence
Data lives in the PDS. If the PDS goes down, data in its volume persists. Without the PDS, no sync can occur.

---

## Nostr

### What's Needed
At least **one Nostr relay** that both devices can connect to. A relay is a simple WebSocket server that stores and forwards Nostr events.

### Self-Hosted (Recommended for Testing)

Docker Compose file: `infra/docker-compose.nostr.yml`

Uses [strfry](https://github.com/hoytech/strfry), a high-performance C++ relay.

```bash
# Start relay
docker compose -f infra/docker-compose.nostr.yml up -d

# Verify (WebSocket on port 7777)
nc -z localhost 7777
```

**Ports:**
| Port | Service | Protocol |
|---|---|---|
| 7777 | WebSocket relay | TCP (WS) |

### Public/Cloud Option
Public relays like `wss://relay.damus.io` or `wss://nos.lol` can be used, but add latency and may rate-limit. Self-hosted is strongly recommended for testing.

### Network Requirements
- Both devices must reach the relay via WebSocket
- Single port (7777 by default)
- No NAT issues — relay acts as intermediary

### Infrastructure Cost
**Minimal.** Single container, ~50MB RAM, disk scales with events stored.

### Persistence
Events are stored in the relay's database. If the relay restarts, events persist in the Docker volume. If the volume is deleted, all events are lost (but clients can re-publish).

---

## Matrix

### What's Needed
A **Matrix homeserver** that both devices can register accounts on and communicate through.

### Self-Hosted (Recommended for Testing)

Docker Compose file: `infra/docker-compose.matrix.yml`

Uses [Conduit](https://conduit.rs/), a lightweight Rust Matrix homeserver.

```bash
# Start homeserver
docker compose -f infra/docker-compose.matrix.yml up -d

# Verify
curl http://localhost:6167/_matrix/client/versions
```

**Ports:**
| Port | Service | Protocol |
|---|---|---|
| 6167 | Matrix HTTP API | TCP |

### Public/Cloud Option
Register accounts on [matrix.org](https://matrix.org), but rate limits and registration captchas make automated testing impractical.

### Network Requirements
- Both devices must reach the homeserver over HTTP
- For same-server testing, only port 6167 is needed
- Federation (multi-server) requires additional DNS/TLS setup

### Infrastructure Cost
**Minimal.** Conduit is very lightweight — ~30MB RAM, single binary in Docker.

### Persistence
Room state and messages are stored in the homeserver's database (RocksDB). Data persists across restarts if the volume is maintained.

---

## Solid

### What's Needed
A **Solid Pod server** that both devices can authenticate to and read/write Linked Data resources.

### Self-Hosted (Recommended for Testing)

Docker Compose file: `infra/docker-compose.solid.yml`

Uses [Community Solid Server (CSS)](https://github.com/CommunitySolidServer/CommunitySolidServer).

```bash
# Start server
docker compose -f infra/docker-compose.solid.yml up -d

# Verify
curl http://localhost:3000/
```

**Ports:**
| Port | Service | Protocol |
|---|---|---|
| 3000 | Solid HTTP API | TCP |

### Public/Cloud Option
[solidcommunity.net](https://solidcommunity.net) offers free pods, but requires manual account creation. [Inrupt Pod Spaces](https://start.inrupt.com/) is another option.

### Network Requirements
- Both devices must reach the Solid server over HTTP
- Single port (3000)
- Authentication may use WebID-OIDC

### Infrastructure Cost
**Minimal.** Single Node.js container, ~100MB RAM.

### Persistence
Data is stored as files/RDF in the server's volume. Persists across restarts. Volume deletion = data loss.

---

## IPFS

### What's Needed
At least **one IPFS daemon** (kubo/go-ipfs) that both devices can interact with. For proper multi-device testing, each device should have its own IPFS node that can discover each other via the DHT or direct peering.

### Self-Hosted (Recommended for Testing)

Docker Compose file: `infra/docker-compose.ipfs.yml`

```bash
# Start IPFS on Device A
docker compose -f infra/docker-compose.ipfs.yml up -d

# Verify
curl -X POST http://localhost:5001/api/v0/id
```

For full multi-device testing, run the same compose on Device B (or use a second IPFS node).

**Ports:**
| Port | Service | Protocol |
|---|---|---|
| 5001 | HTTP API | TCP |
| 4001 | Swarm (libp2p) | TCP + UDP |
| 8080 | Gateway (read-only) | TCP |

### Public/Cloud Option
Public IPFS gateways exist for reading, but writing requires your own node. Pinning services (Pinata, Infura) can host content but add complexity.

### Network Requirements
- API port (5001) for AD4M executor communication
- Swarm port (4001) for peer discovery and data exchange
- Outbound internet for DHT bootstrap
- Both IPFS nodes need to be able to reach each other on port 4001

### Infrastructure Cost
**Minimal to moderate.** ~200MB RAM per node, disk scales with pinned content.

### Persistence
IPFS data is content-addressed and pinned locally. Unpinned data may be garbage-collected. Docker volume preserves the datastore across restarts.

---

## Hypercore

### What's Needed
**Nothing.** Hypercore uses [Hyperswarm](https://docs.holepunch.to/building-blocks/hyperswarm), a distributed networking stack with built-in DHT for peer discovery and NAT hole-punching.

### Network Requirements
- **Outbound internet** on both machines (for DHT bootstrap)
- **UDP** for hole-punching (may not work behind strict corporate firewalls)
- If both machines are on the same LAN, mDNS can accelerate discovery
- No specific ports need to be opened inbound (Hyperswarm handles NAT traversal)

### Persistence
Hypercore data is append-only and stored locally. Each peer maintains its own copy. No central point of failure — if both peers go offline, data persists locally and syncs when they reconnect.

### Notes
- Fully P2P — no Docker infrastructure needed
- Initial peer discovery may take 5-15 seconds via DHT
- LAN discovery via mDNS is near-instant
- Consider increasing `SYNC_WAIT_SECONDS` for initial Hypercore tests

---

## Docker Compose Files Reference

All compose files are in the `infra/` directory:

| File | Protocol | Primary Port |
|---|---|---|
| `docker-compose.nostr.yml` | Nostr | 7777 |
| `docker-compose.matrix.yml` | Matrix | 6167 |
| `docker-compose.solid.yml` | Solid | 3000 |
| `docker-compose.atproto.yml` | AT Protocol | 2583 |
| `docker-compose.ipfs.yml` | IPFS | 5001, 4001, 8080 |

### Common Operations

```bash
# Start specific infrastructure
docker compose -f infra/docker-compose.nostr.yml up -d

# View logs
docker compose -f infra/docker-compose.nostr.yml logs -f

# Stop and remove volumes
docker compose -f infra/docker-compose.nostr.yml down -v

# Stop all infrastructure
for f in infra/docker-compose.*.yml; do
    docker compose -f "$f" down -v
done
```

### Resource Estimates

Running all 5 infrastructure services simultaneously:

| Resource | Estimate |
|---|---|
| RAM | ~500MB total |
| Disk | ~1GB (images) + data volumes |
| CPU | Negligible at test scale |
| Network | LAN traffic only (if self-hosted) |
