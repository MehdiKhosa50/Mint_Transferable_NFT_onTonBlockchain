# NFT Collection on Ton Blockchain Using Tact

This project implements a NFT (Non-Fungible Token) collection smart contract on the TON blockchain using Tact. NFTs are transferrable tokens, often used for credentials, achievements, or memberships that are intrinsically tied to a specific address.

Credit: Youtube [Nikandr Surkov](https://www.youtube.com/@NikandrSurkov) for more tutorials and guides.

## About Tact

Tact is a high-level, statically-typed language designed specifically for writing smart contracts on the TON blockchain. It offers a more developer-friendly syntax compared to FunC (the native low-level language of TON), while still compiling down to efficient FunC code. This project showcases the use of Tact for creating complex smart contract systems like NFTs.

## Project Structure

- `contracts`: Source code of the smart contracts written in Tact.
- `wrappers`: Wrapper classes for the contracts, including serialization primitives and compilation functions.
- `tests`: Test suite for the contracts.
- `scripts`: Utility scripts, including deployment and minting scripts.

## Prerequisites

- Node.js (v14 or newer recommended)
- Yarn or NPM
- TON development environment (follow [TON documentation](https://ton.org/docs/) for setup)
- Tact compiler (installed as a project dependency)

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/MehdiKhosa50/Mint_Transferable_NFT_onTonBlockchain
   cd Mint_Transferable_NFT_onTonBlockchain
   ```

2. Install dependencies:
   ```
   yarn install
   ```
   or
   ```
   npm install
   ```

## Building the Contract

To build the smart contract (this compiles Tact to FunC, then to Fift, and finally to a cell (BOC) file):

```
npx blueprint build
```

or

```
yarn blueprint build
```

## Testing

Run the test suite with:

```
npx blueprint test
```

or

```
yarn blueprint test
```

## Preparing Metadata

Before deploying your Soulbound NFT collection, you need to prepare the metadata. This involves creating JSON files for both the collection and individual items, and uploading them to IPFS. Follow these steps:

1. Create a folder for your metadata.

2. In this folder, create two JSON files:

   a. `meta.json` - metadata for the NFT collection:

   ```json
   {
     "name": "NFTCollection by Muhammad Muntazir Mehdi",
     "description": "NFT collection created by Muhammad Muntazir Mehdi.",
     "image": "https://brown-left-fowl-93.mypinata.cloud/files/bafkreid4jiagap7clbprixxxug3a5zcf7mzvtzexbbspnkudlccif3vj6q",
     "cover_image": "https://brown-left-fowl-93.mypinata.cloud/files/bafkreid4jiagap7clbprixxxug3a5zcf7mzvtzexbbspnkudlccif3vj6q",
     "social_links": [
       {
         "name": "Website",
         "url": "https://mehdikhosa.vercel.app/"
       },
       {
         "name": "LinkedIn",
         "url": "https://www.linkedin.com/in/mehdikhosa/"
       },
       {
         "name": "Telegram",
         "url": "https://t.me/mehdikhosa50"
       },
       {
         "name": "GitHub",
         "url": "https://github.com/MehdiKhosa50/"
       }
     ]
   }
   ```

   b. `item.json` - metadata for each NFT item:

   ```json
   {
     "name": "NFT Item",
     "description": "NFT item from ArgonTeq collection created by Muhammad Muntazir Mehdi.",
     "image": "https://brown-left-fowl-93.mypinata.cloud/files/bafkreid4jiagap7clbprixxxug3a5zcf7mzvtzexbbspnkudlccif3vj6q"
   }
   ```

3. Upload your images to IPFS (you can use services like Pinata) and replace the placeholder URLs in your JSON files with the actual IPFS URLs of your images.

4. Upload the entire folder containing both JSON files to IPFS.

5. Use the IPFS URL of the uploaded folder as the `CONTENT_URL` in your deployment script (`scripts/deployNftCollection.ts`).

Note: Make sure to replace the placeholder URLs and information in the JSON files with your own content and IPFS links.

## Deployment

To deploy the NFT collection:

1. Ensure you have sufficient TON in your deployer wallet.
2. Update the `CONTENT_URL` in the deployment script (`scripts/deployNftCollection.ts`) with your NFT metadata URL.
3. Run the deployment script:

```
npx blueprint run deployNftCollection
```

The script will output the deployed collection address and the address of the first minted NFT.

## Minting New NFTs

To mint additional NFTs:

1. Update the NFT collection address in the minting script (`scripts/mintNewNft.ts`).
2. Run the minting script:

```
npx blueprint run mintNewNft
```

The script will output the newly minted NFT's index and address.

## Smart Contract Details

The NFT collection, written in Tact, consists of two main contracts:

1. `NftCollection`: Manages the collection of NFTs.
2. `NftItem`: Represents individual NFT items.

Key features:
- transferrable NFTs
- Minting functionality
- Ownership proof mechanism
- Revocation capability by authority

## License

This project is licensed under the MIT License.
