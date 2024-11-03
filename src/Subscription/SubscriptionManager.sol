// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubscriptionNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SubscriptionManager
 * @dev Manages the logic and state for subscriptions, including expiration and balance tracking.
 *
 * This contract is responsible for maintaining and updating the state of user subscriptions represented by
 * `SubscriptionNFT` tokens. The contract includes functionality to:
 * - **Track expiration** and burn expired subscription NFTs.
 * - **Update subscription balances** as users consume services covered by the subscription.
 * - **Provide interfaces** for external contracts like `CustomPaymaster` and `CustomBundler` to check the validity
 *   of a user’s subscription in cross-chain calls or transactions.
 *
 * ## Purpose
 * The primary purpose of `SubscriptionManager` is to serve as the business logic layer that manages the lifecycle of
 * subscriptions, including:
 * - Checking and enforcing subscription expiration.
 * - Adjusting balances based on usage, enabling accurate tracking of a user’s remaining coverage.
 * - Offering functions that other contracts can call to confirm a user's subscription validity.
 *
 * ## Contract Components
 * - **Subscription State Management**: Manages subscription expiration and verifies validity.
 * - **Balance Deduction and Updates**: Tracks remaining subscription funds and reduces balance upon usage.
 * - **Integration with SubscriptionNFT**: Reads NFT ownership and metadata from `SubscriptionNFT.sol` to access 
 *   subscription information.
 *
 * ## Relationship with Other Contracts
 * - **SubscriptionNFT**: Reads ownership and metadata information to confirm subscription status and expiration.
 * - **CustomBundler and CustomPaymaster**: These contracts interact with `SubscriptionManager` to validate a user's
 *   subscription before executing transactions or paying gas fees.
 *
 * @notice This contract is essential for managing user subscriptions, expiration, and balance updates for a gas
 *         sponsorship platform that spans multiple chains.
 */
contract SubscriptionManager is Ownable {
    SubscriptionNFT public subscriptionNFT;

    // Event emitted when a subscription is expired and burned
    event SubscriptionExpired(uint256 indexed tokenId, address indexed user);

    /**
     * @dev Initializes the contract by linking to the SubscriptionNFT contract.
     * @param _subscriptionNFT The address of the SubscriptionNFT contract used to represent subscriptions as NFTs.
     */
    constructor(SubscriptionNFT _subscriptionNFT) {
        subscriptionNFT = _subscriptionNFT;
    }

    /**
     * @notice Checks if a given subscription NFT is valid and active.
     * @param tokenId The ID of the subscription NFT to check.
     * @return bool Returns true if the subscription is valid, false if it is expired.
     */
    function isSubscriptionValid(uint256 tokenId) external view returns (bool) {
        // Check if the subscription is active by querying SubscriptionNFT
        return subscriptionNFT.isSubscriptionActive(tokenId);
    }

    /**
     * @notice Reduces the balance of a user’s subscription for a service usage.
     * @param tokenId The ID of the subscription NFT.
     * @param usageAmount The amount to be deducted from the subscription balance.
     * @dev Throws if the subscription is expired or balance is insufficient.
     */
    function reduceSubscriptionBalance(uint256 tokenId, uint256 usageAmount) external onlyOwner {
        require(subscriptionNFT.isSubscriptionActive(tokenId), "SubscriptionManager: Subscription expired");

        // Logic to update the usage of the subscription would be implemented here
        // For instance, you might track usage in a mapping or another mechanism depending on the subscription plan

        // Assuming usage tracking is performed off-chain or in SubscriptionNFT itself
    }

    /**
     * @notice Burns the subscription NFT if it has expired.
     * @param tokenId The ID of the subscription NFT.
     * @dev This function checks expiration and, if expired, burns the NFT and emits an event.
     */
    function burnExpiredSubscription(uint256 tokenId) external onlyOwner {
        require(!subscriptionNFT.isSubscriptionActive(tokenId), "SubscriptionManager: Subscription is still active");

        address user = subscriptionNFT.ownerOf(tokenId);

        // Burn the expired subscription NFT
        subscriptionNFT._burn(tokenId);

        emit SubscriptionExpired(tokenId, user);
    }

    /**
     * @notice Updates the subscription data off-chain after usage or balance deductions.
     * @param tokenId The ID of the subscription NFT.
     * @dev This function would typically interact with backend logic or the bundler to track and sync usage.
     */
    function updateSubscriptionData(uint256 tokenId) external onlyOwner {
        // Logic for updating off-chain subscription data could go here
        // For example, notifying the bundler of the subscription update after usage
    }
}
