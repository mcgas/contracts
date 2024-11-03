// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// SubscriptionManager.sol:

// Role: Handles business logic for subscriptions (e.g., expiration management that the NFT will be burned, updates the subscription data like how much is used to subtract the amount of token, ).

// Details: Maintains subscription status, expiration, and balance updates. Provides functions for other contracts (e.g., Paymaster in a cross-chain call) to check the validity of a user’s subscription.

// Relationship:
// Reads NFT ownership and metadata from SubscriptionNFT.sol.
// Used by CustomBundler and CustomPaymaster for checking the user’s subscription status.
