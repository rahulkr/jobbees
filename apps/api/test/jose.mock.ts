// Jest-only shim for jose.
//
// jose v6 ships an ESM build that jest's CJS sandbox can't parse. Node 24 loads
// it fine at runtime; only jest struggles. Tests that exercise Apple
// verification control `jwtVerify` directly. Production uses real jose.
export const createRemoteJWKSet = jest.fn(() => 'mock-jwks');
export const jwtVerify = jest.fn();
