/**
 * Local Neighbourhood Store
 * 
 * Stores neighbourhood metadata locally in the language's storage directory.
 * Drop-in replacement for the centralized neighbourhood-store for local testing.
 * No network dependencies.
 */
import { defineLanguage, agentCreateSignedExpression, hash } from "@coasys/ad4m-ldk";

const STORE = new Map();

const language = defineLanguage({
    name: "local-neighbourhood-store",
    version: "0.1.0",

    async init() {},
    async teardown() {},
    interactions() { return []; },

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
        },
    },
});

export const {
    name,
    version,
    init,
    teardown,
    interactions,
    expressionGet,
    expressionCreate,
} = language;
