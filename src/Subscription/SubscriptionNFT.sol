// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Name: SubscriptionNFT.sol

// Role: Manages the NFT-based subscription tokens that represent user subscriptions.

// Details: Implements ERC-721 functionality, representing each user’s subscription as an NFT. Each NFT is tied to subscription metadata (e.g., start date, end date,
// payed token and its amount at the purchase time, the addresses which are going to be registerred under sponsorship, etc).
// The NFT will be mint for the user as its subscription purchase.

// Relationship: Interacts with SubscriptionManager.sol to handle subscription state and user balances.
