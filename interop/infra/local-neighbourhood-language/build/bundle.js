// ../../coasys/ad4m/ad4m-ldk/js/lib/imports.js
import {
  agentDid,
  agentSigningKeyId,
  agentSign,
  agentSignStringHex,
  agentCreateSignedExpression,
  agentGetAllLocalUserDids,
  agentCreateSignedExpressionForUser,
  agentDidForUser,
  holochainRegisterDnas,
  holochainCall,
  holochainCallAsync,
  httpFetch,
  hash,
  languageStorageDirectory,
  languageAddress,
  languageSettings,
  emitPerspectiveDiff,
  emitSyncStateChange,
  emitTelepresenceSignal,
  emitSignal,
  storageGet,
  storagePut,
  storageDelete,
  storageListKeys,
  readStorageFile,
  writeStorageFile
} from "ad4m:host";

// ../../coasys/ad4m/ad4m-ldk/js/lib/defineLanguage.js
function defineLanguage(spec) {
  const out = {
    name: spec.name,
    version: spec.version,
    init: spec.init.bind(spec)
  };
  if (typeof spec.isPublic === "boolean") {
    const v = spec.isPublic;
    out.isPublic = () => v;
  }
  if (spec.teardown)
    out.teardown = spec.teardown.bind(spec);
  if (spec.interactions)
    out.interactions = spec.interactions.bind(spec);
  if (spec.expression) {
    const e = spec.expression;
    if (e.get)
      out.expressionGet = e.get.bind(e);
    if (e.create)
      out.expressionCreate = e.create.bind(e);
    if (e.addressOf)
      out.expressionAddressOf = e.addressOf.bind(e);
    if (e.isImmutable)
      out.isImmutableExpression = e.isImmutable.bind(e);
    if (e.icon)
      out.expressionIcon = e.icon.bind(e);
    if (e.constructorIcon)
      out.expressionConstructorIcon = e.constructorIcon.bind(e);
  }
  if (spec.languageSource) {
    out.languageGetSource = spec.languageSource.getSource.bind(spec.languageSource);
  }
  if (spec.commit) {
    out.perspectiveCommit = spec.commit.commit.bind(spec.commit);
  }
  if (spec.sync) {
    const s = spec.sync;
    out.perspectiveSyncSync = s.sync.bind(s);
    out.perspectiveSyncRender = s.render.bind(s);
    out.perspectiveSyncCurrentRevision = s.currentRevision.bind(s);
  }
  if (spec.query) {
    out.perspectiveQuerySupportedKinds = spec.query.supportedKinds.bind(spec.query);
    out.perspectiveQueryRun = spec.query.run.bind(spec.query);
  }
  if (spec.peers) {
    out.peersSetLocal = spec.peers.setLocal.bind(spec.peers);
    out.peersRemote = spec.peers.remote.bind(spec.peers);
  }
  if (spec.telepresence) {
    const t = spec.telepresence;
    if (t.setOnlineStatus)
      out.telepresenceSetOnlineStatus = t.setOnlineStatus.bind(t);
    if (t.getOnlineAgents)
      out.telepresenceGetOnlineAgents = t.getOnlineAgents.bind(t);
    if (t.sendSignal)
      out.telepresenceSendSignal = t.sendSignal.bind(t);
    if (t.sendBroadcast)
      out.telepresenceSendBroadcast = t.sendBroadcast.bind(t);
    if (t.registerSignalCallback)
      out.telepresenceRegisterSignalCallback = t.registerSignalCallback.bind(t);
  }
  if (spec.handleHolochainSignal) {
    out.handleHolochainSignal = spec.handleHolochainSignal.bind(spec);
  }
  return out;
}

// ../ad4m-wind-tunnel/interop/infra/local-neighbourhood-language/index.ts
var STORE = /* @__PURE__ */ new Map();
var language = defineLanguage({
  name: "local-neighbourhood-store",
  version: "0.1.0",
  async init() {
  },
  async teardown() {
  },
  interactions() {
    return [];
  },
  expression: {
    async create(neighbourhood) {
      const address = hash(JSON.stringify(neighbourhood));
      const expression = agentCreateSignedExpression(neighbourhood);
      STORE.set(address, JSON.stringify(expression));
      return address;
    },
    async get(address) {
      const data = STORE.get(address);
      if (!data) return null;
      try {
        return JSON.parse(data);
      } catch {
        return null;
      }
    }
  }
});
var {
  name,
  version,
  init,
  teardown,
  interactions,
  expressionGet,
  expressionCreate
} = language;
export {
  expressionCreate,
  expressionGet,
  init,
  interactions,
  name,
  teardown,
  version
};
