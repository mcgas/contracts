// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Counters.sol";

/**
 * @title SubscriptionNFT
 * @dev A contract for managing user subscriptions represented as ERC-721 NFTs.
 *
 * This contract is designed to represent and manage user subscriptions as NFTs (non-fungible tokens) on the blockchain.
 * Each subscription is minted as an NFT under the ERC-721 standard, allowing each user subscription to be unique
 * and tradable. The NFT serves as proof of the subscription, containing metadata such as start date, end date, payment
 * details, and addresses covered by the gas sponsorship.
 *
 * ## Purpose
 * The primary purpose of this contract is to handle subscriptions as unique tokens, enabling users to own a specific
 * subscription instance that can be verified on-chain and potentially transferred if desired. By storing essential
 * subscription data within each token, this contract facilitates:
 * - **Ownership** of subscriptions as tokens for easy on-chain verification and transferability.
 * - **Metadata storage** for each subscription, such as start and end dates, payment method, amount, and sponsored addresses.
 * - **Interoperability** with other smart contracts like `SubscriptionManager.sol`, which may read and modify subscription status
 *    data when required.
 *
 * ## Contract Components
 * - **ERC-721 Token Functionality**: Leverages OpenZeppelin's ERC-721 implementation for NFT functionality.
 * - **Ownership Management**: Restricted functions to the contract owner, such as subscription minting, ensuring controlled issuance.
 * - **Data Structuring and Access**: Defines a `Subscription` struct to store subscription details for each NFT and provides
 *   functions to retrieve and check subscription status.
 *
 * ## Relationship with Other Contracts
 * - **SubscriptionManager.sol**: This contract is expected to interact with `SubscriptionManager`, which will use `SubscriptionNFT`
 *    to verify users' active subscriptions. The `SubscriptionManager` contract will serve as an interface for higher-level
 *    subscription management functions, allowing updates to subscription status and validation during transactions.
 *
 * @notice This contract is a core component of a gas sponsorship platform, enabling users to acquire and verify
 *         subscriptions for gas coverage across multiple chains. Each subscription NFT contains data relevant to
 *         gas sponsorship.
 */
contract SubscriptionNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Subscription {
        uint256 startDate;
        uint256 endDate;
        address paymentToken;
        uint256 amountPaid;
        address[] sponsoredAddresses;
    }

    // Mapping of token ID to Subscription details
    mapping(uint256 => Subscription) private _subscriptions;

    // Event emitted when a new subscription NFT is minted
    event SubscriptionMinted(
        uint256 indexed tokenId,
        address indexed subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 amountPaid,
        address[] sponsoredAddresses
    );

    constructor() ERC721("SubscriptionNFT", "SUBNFT") {}

    /**
     * @dev Mints a new subscription NFT for a user.
     * @param subscriber The address of the user purchasing the subscription.
     * @param startDate The start date of the subscription (as a Unix timestamp).
     * @param endDate The end date of the subscription (as a Unix timestamp).
     * @param paymentToken The address of the token used for payment.
     * @param amountPaid The amount of tokens paid for the subscription.
     * @param sponsoredAddresses The addresses to be sponsored under this subscription.
     * @return tokenId The token ID of the newly minted subscription NFT.
     */
    function mintSubscription(
        address subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 amountPaid,
        address[] memory sponsoredAddresses
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Mint the NFT to the subscriber
        _safeMint(subscriber, tokenId);

        // Store subscription details
        _subscriptions[tokenId] = Subscription({
            startDate: startDate,
            endDate: endDate,
            paymentToken: paymentToken,
            amountPaid: amountPaid,
            sponsoredAddresses: sponsoredAddresses
        });

        emit SubscriptionMinted(
            tokenId,
            subscriber,
            startDate,
            endDate,
            paymentToken,
            amountPaid,
            sponsoredAddresses
        );

        return tokenId;
    }

    /**
     * @dev Retrieves the subscription details for a specific token ID.
     * @param tokenId The token ID of the subscription NFT.
     * @return startDate The start date of the subscription.
     * @return endDate The end date of the subscription.
     * @return paymentToken The address of the token used for payment.
     * @return amountPaid The amount of tokens paid for the subscription.
     * @return sponsoredAddresses The addresses sponsored under this subscription.
     */
    function getSubscription(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 startDate,
            uint256 endDate,
            address paymentToken,
            uint256 amountPaid,
            address[] memory sponsoredAddresses
        )
    {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription memory subscription = _subscriptions[tokenId];
        return (
            subscription.startDate,
            subscription.endDate,
            subscription.paymentToken,
            subscription.amountPaid,
            subscription.sponsoredAddresses
        );
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

        Subscription memory subscription = _subscriptions[tokenId];
        return (block.timestamp >= subscription.startDate &&
            block.timestamp <= subscription.endDate);
    }
}
