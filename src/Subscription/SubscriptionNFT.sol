// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SubscriptionNFT
 * @dev A contract for managing user subscriptions represented as ERC-721 NFTs.
 *
 * This contract represents user subscriptions as non-fungible tokens (NFTs) under the ERC-721 standard. Each subscription
 * is minted as an NFT, providing a unique, tradable token that serves as proof of the subscription. Each NFT contains
 * metadata pertinent to the subscription, such as start and end dates, payment details, remaining balance, and sponsored
 * addresses.
 *
 * ## Purpose
 * The primary purpose of this contract is to manage and represent gas sponsorship subscriptions as NFTs. By using the ERC-721
 * standard, subscriptions are verifiable on-chain, transferable, and can store key subscription information within each token.
 * This design supports:
 * - **Ownership** of subscriptions, with NFTs representing a user's specific subscription instance, allowing for transparent
 *   on-chain verification and transferability.
 * - **Metadata storage** for each subscription, including details such as start and end dates, payment method, paid amount,
 *   remaining balance (tracked by `remainingAmount`), and sponsored addresses.
 * - **Interoperability** with other contracts, such as `SubscriptionManager`, which reads and updates subscription data.
 *
 * ## Contract Components
 * - **ERC-721 Functionality**: Uses OpenZeppelin’s ERC-721 implementation to support NFT minting, ownership, and transfers.
 * - **Subscription Management**: Stores subscription details in a `Subscription` struct, with functions to retrieve, update,
 *   and manage each subscription instance.
 * - **Ownership Controls**: Restricts certain functions, such as subscription minting, to the contract owner, ensuring controlled issuance.
 *
 * ## Relationship with Other Contracts
 * - **SubscriptionManager.sol**: The `SubscriptionManager` contract interacts with `SubscriptionNFT` to verify and update
 *   active subscriptions. It plays a central role in deducting fees from the `remainingAmount` on each transaction,
 *   thereby managing the subscription’s balance as gas fees are sponsored.
 *
 * @notice This contract is a core component of a gas sponsorship platform that allows users to purchase subscriptions
 *         for gas fee coverage across multiple chains. Each subscription NFT stores critical data for cross-chain gas
 *         sponsorship management.
 */
contract SubscriptionNFT is ERC721, Ownable {
    /// Represents each user's subscription data
    struct Subscription {
        uint256 startDate; ///< Start date of the subscription in Unix timestamp
        uint256 endDate; ///< End date of the subscription in Unix timestamp
        address paymentToken; ///< Address of the token used for the subscription payment
        uint256 paidAmount; ///< Total amount of tokens paid at subscription purchase
        uint256 remainingAmount; ///< Remaining amount of tokens after transaction fees are deducted
        address[] sponsoredAddresses; ///< List of addresses covered under this subscription for gas sponsorship
    }

    /// Mapping from token ID to Subscription data
    mapping(uint256 => Subscription) public subscriptions;

    /// Counter to generate unique subscription token IDs
    uint256 private _tokenIdCounter;

    /**
     * @dev Emitted when a new subscription is created.
     * @param tokenId Unique token ID representing the subscription
     * @param subscriber Address of the user who purchased the subscription
     * @param startDate Start date of the subscription
     * @param endDate End date of the subscription
     * @param paymentToken Address of the token used for the subscription payment
     * @param amountPaid Total amount of tokens paid for the subscription
     */
    event SubscriptionMinted(
        uint256 indexed tokenId,
        address indexed subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 amountPaid
    );

    constructor() ERC721("SubscriptionNFT", "SUBNFT") Ownable(_msgSender()) {}

    /**
     * @dev Mints a new subscription NFT for a user.
     * @param subscriber The address of the user purchasing the subscription.
     * @param startDate The start date of the subscription (as a Unix timestamp).
     * @param endDate The end date of the subscription (as a Unix timestamp).
     * @param paymentToken The address of the token used for payment.
     * @param paidAmount The amount of tokens paid for the subscription.
     * @param sponsoredAddresses The addresses to be sponsored under this subscription.
     * @return tokenId The token ID of the newly minted subscription NFT.
     *
     * @dev The `remainingAmount` will be initially set to the `paidAmount`,
     * and will be deducted by SubscriptionManager as transactions occur.
     */
    function mintSubscription(
        address subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 paidAmount,
        address[] calldata sponsoredAddresses
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = ++_tokenIdCounter;

        // Store subscription details
        subscriptions[tokenId] = Subscription({
            startDate: startDate,
            endDate: endDate,
            paymentToken: paymentToken,
            paidAmount: paidAmount,
            remainingAmount: paidAmount,
            sponsoredAddresses: sponsoredAddresses
        });

        // Mint the NFT to the subscriber
        _safeMint(subscriber, tokenId);

        emit SubscriptionMinted(
            tokenId,
            subscriber,
            startDate,
            endDate,
            paymentToken,
            paidAmount
        );

        return tokenId;
    }

    /**
     * @dev Checks if a subscription is still active.
     * @param tokenId The token ID of the subscription NFT.
     * @return bool True if the subscription is active, false otherwise.
     */
    function isSubscriptionActive(
        uint256 tokenId
    ) external view returns (bool) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription memory subscription = subscriptions[tokenId];
        return (subscription.remainingAmount > 0 &&
            block.timestamp >= subscription.startDate &&
            block.timestamp <= subscription.endDate);
    }

    /**
     * @notice Updates the `remainingAmount` of tokens for a given subscription.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param amountDeducted Amount to deduct from the `remainingAmount`.
     *
     * @dev This function is called by SubscriptionManager to track deductions
     * from the user’s subscription as gas fees are paid.
     */
    function updateRemainingAmount(
        uint256 tokenId,
        uint256 amountDeducted
    ) external onlyOwner {
        require(
            _exists(tokenId),
            "SubscriptionNFT: Subscription does not exist"
        );
        Subscription storage subscription = subscriptions[tokenId];

        require(
            subscription.remainingAmount >= amountDeducted,
            "SubscriptionNFT: Insufficient remaining amount"
        );
        subscription.remainingAmount -= amountDeducted;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return subscriptions[tokenId].startDate != 0;
    }
}
