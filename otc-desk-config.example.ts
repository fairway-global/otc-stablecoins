/**
 * otc-desk-config.example.ts
 * 
 * Example configuration showing how your OTC desk can reference
 * both real devnet tokens AND your mock stablecoins.
 * 
 * Copy this, replace mock mints with values from mint-addresses.json
 * after running the creation script.
 */

import { PublicKey } from "@solana/web3.js";

// Token program IDs — your OTC desk MUST handle both
export const TOKEN_PROGRAMS = {
  LEGACY: new PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"),
  TOKEN_2022: new PublicKey("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"),
} as const;

export interface StablecoinEntry {
  symbol: string;
  name: string;
  mint: PublicKey;
  decimals: number;
  programId: PublicKey;
  isReal: boolean;           // true = official devnet token, false = mock
  faucetUrl?: string;        // where to get test tokens
  peg: string;               // USD, EUR, CHF, GBP, JPY, SGD, AED
  rate?: number;             // approximate USD rate for display (not for execution)
}

// =============================================================================
// REAL devnet tokens — use official faucets
// =============================================================================

const REAL_TOKENS: StablecoinEntry[] = [
  {
    symbol: "USDC",
    name: "USD Coin",
    mint: new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"),
    decimals: 6,
    programId: TOKEN_PROGRAMS.LEGACY,
    isReal: true,
    faucetUrl: "https://faucet.circle.com",
    peg: "USD",
    rate: 1.0,
  },
  {
    symbol: "PYUSD",
    name: "PayPal USD",
    mint: new PublicKey("CXk2AMBfi3TwaEL2468s6zP8xq9NxTXjp9gjMgzeUynM"),
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: true,
    faucetUrl: "https://faucet.paxos.com",
    peg: "USD",
    rate: 1.0,
  },
  // EURC real devnet — get the mint from Circle faucet, then update here
  // {
  //   symbol: "EURC",
  //   name: "Euro Coin",
  //   mint: new PublicKey("..."),
  //   decimals: 6,
  //   programId: TOKEN_PROGRAMS.TOKEN_2022,
  //   isReal: true,
  //   faucetUrl: "https://faucet.circle.com",
  //   peg: "EUR",
  //   rate: 1.08,
  // },
];

// =============================================================================
// MOCK tokens — replace mints with values from mint-addresses.json
// =============================================================================

const MOCK_TOKENS: StablecoinEntry[] = [
  {
    symbol: "USDT",
    name: "Tether USD (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "USD",
    rate: 1.0,
  },
  {
    symbol: "USDG",
    name: "Global Dollar (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "USD",
    rate: 1.0,
  },
  {
    symbol: "USX",
    name: "USX Solstice (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "USD",
    rate: 1.0,
  },
  {
    symbol: "CHF",
    name: "Swiss Franc (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "CHF",
    rate: 1.12, // approx CHF/USD
  },
  {
    symbol: "GBP",
    name: "British Pound (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "GBP",
    rate: 1.26, // approx GBP/USD
  },
  {
    symbol: "JPY",
    name: "Japanese Yen (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "JPY",
    rate: 0.0067, // approx JPY/USD
  },
  {
    symbol: "SGD",
    name: "Singapore Dollar (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "SGD",
    rate: 0.75, // approx SGD/USD
  },
  {
    symbol: "AED",
    name: "UAE Dirham (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "AED",
    rate: 0.2723, // 1 AED = 0.2723 USD (pegged at 3.6725)
  },
  {
    symbol: "EURC",
    name: "Euro Coin (Mock)",
    mint: new PublicKey("11111111111111111111111111111111"), // <-- REPLACE
    decimals: 6,
    programId: TOKEN_PROGRAMS.TOKEN_2022,
    isReal: false,
    peg: "EUR",
    rate: 1.08,
  },
];

// =============================================================================
// Combined registry
// =============================================================================

export const ALL_STABLECOINS = [...REAL_TOKENS, ...MOCK_TOKENS];

export function getToken(symbol: string): StablecoinEntry | undefined {
  return ALL_STABLECOINS.find(
    (t) => t.symbol.toUpperCase() === symbol.toUpperCase()
  );
}

export function getTokensByPeg(peg: string): StablecoinEntry[] {
  return ALL_STABLECOINS.filter(
    (t) => t.peg.toUpperCase() === peg.toUpperCase()
  );
}

/**
 * Get the correct token program for a given mint.
 * Critical for building correct transfer instructions!
 */
export function getProgramForMint(mintAddress: string): PublicKey {
  const token = ALL_STABLECOINS.find(
    (t) => t.mint.toBase58() === mintAddress
  );
  return token?.programId ?? TOKEN_PROGRAMS.LEGACY;
}

// =============================================================================
// OTC pair definitions — which swaps does your desk support?
// =============================================================================

export interface OTCPair {
  base: string;     // what you're selling
  quote: string;    // what you're buying
  minSize: number;  // minimum order in base units
  maxSize: number;  // maximum order in base units
}

export const OTC_PAIRS: OTCPair[] = [
  // USD stablecoin swaps
  { base: "USDC",  quote: "USDT",  minSize: 100,  maxSize: 1_000_000 },
  { base: "USDC",  quote: "PYUSD", minSize: 100,  maxSize: 1_000_000 },
  { base: "USDC",  quote: "USDG",  minSize: 100,  maxSize: 1_000_000 },
  { base: "USDC",  quote: "USX",   minSize: 100,  maxSize: 1_000_000 },

  // FX pairs
  { base: "USDC",  quote: "EURC",  minSize: 100,  maxSize: 500_000 },
  { base: "USDC",  quote: "CHF",   minSize: 100,  maxSize: 500_000 },
  { base: "USDC",  quote: "GBP",   minSize: 100,  maxSize: 500_000 },
  { base: "USDC",  quote: "JPY",   minSize: 1000, maxSize: 500_000 },
  { base: "USDC",  quote: "SGD",   minSize: 100,  maxSize: 500_000 },
  { base: "USDC",  quote: "AED",   minSize: 100,  maxSize: 500_000 },

  // EUR cross pairs
  { base: "EURC",  quote: "CHF",   minSize: 100,  maxSize: 500_000 },
  { base: "EURC",  quote: "GBP",   minSize: 100,  maxSize: 500_000 },
];
