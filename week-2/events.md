# How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable? Explain how you would accomplish this if you were creating an NFT marketplace.



OpenSea can quickly determine which NFTs an address owns by indexing ownership events and maintaining an off-chain database. When an NFT is transferred, minted, or burned, these events are emitted by the smart contract. OpenSea listens to these events and updates its database accordingly. This allows OpenSea to query its database to quickly determine the NFTs owned by a specific address.

If I were creating an NFT marketplace, I would implement a similar approach by:

1. Using the services like squid or the graph, implement an indexer to listen to Transfer, Mint, Burn or other events based on requirements.
2. Maintaining an off-chain database based on these events.
3. Updating the database in real-time as new events are received.
4. Providing an API endpoint to query the database for NFTs owned by a specific address.

This approach ensures that the marketplace can quickly and efficiently determine NFT ownership without relying on the ERC721 enumerable extension.
