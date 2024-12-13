import { Address, beginCell, fromNano, toNano } from '@ton/core';
import { NftCollection } from '../wrappers/NftCollection';
import { NetworkProvider } from '@ton/blueprint';
import { mnemonicToWalletKey } from '@ton/crypto';
import { WalletContractV1R1, WalletContractV3R2, WalletContractV4 } from '@ton/ton';

export async function run(provider: NetworkProvider) {
    const COLLECTION_ADDRESS = 'EQD_xWbr46DyyiBDdXVUgbNkgLY9uM0hbGYf1AL1RwW1fzjF';
    const nftCollection = provider.open(NftCollection.fromAddress(Address.parse(COLLECTION_ADDRESS)));

    // Define the mnemonic for Account 2 (full 24-word mnemonic)
    const account2Mnemonic = ['Your full 24-word mnemonic for Account 2'];

    try {
        // Generate wallet key from mnemonic
        const walletKey = await mnemonicToWalletKey(account2Mnemonic);

        // Create a wallet contract for the specific account
        const wallet = WalletContractV3R2.create({
            publicKey: walletKey.publicKey,
            workchain: 0, // standard workchain
        });

        console.log('Wallet Address:', wallet.address.toString());

        // Get current collection data
        const collectionData = await nftCollection.getGetCollectionData();
        const nextIndex = collectionData.next_item_index;
        console.log('Minting NFT with index:', nextIndex.toString());

        // Prepare individual NFT metadata
        const OFFCHAIN_CONTENT_PREFIX = 0x01;
        const NFT_METADATA_URL = `https://brown-left-fowl-93.mypinata.cloud/ipfs/bafkreiaaon5p3ot5j3zwcufmfez72mww4fbukxzvetqsme5eunhrgpqwra?pinataGatewayToken=Pt9ebBt6Lq3lboPVJtZkbiteF2O28CNqM4fGuundgLYRfwydZqhbduu-EGIj-H0A`;

        // Get total mint cost
        const mintCost = await nftCollection.getGetNftMintTotalCost();
        console.log('Mint cost:', fromNano(mintCost), 'TON');

        // Create individual content cell
        const itemContent = beginCell()
            .storeInt(OFFCHAIN_CONTENT_PREFIX, 8)
            .storeStringRefTail(NFT_METADATA_URL)
            .endCell();

        // Mint NFT
        await nftCollection.send(
            provider.sender(), // Default sender
            {
                value: mintCost + toNano('0.05'), // Adding extra for gas
                bounce: true,
            },
            'Mint',
        );

        console.log('Minting transaction sent');

        // Wait for transaction processing
        await new Promise((resolve) => setTimeout(resolve, 20000));

        // Verify minting
        const newCollectionData = await nftCollection.getGetCollectionData();
        if (newCollectionData.next_item_index > nextIndex) {
            try {
                const nftAddress = await nftCollection.getGetNftAddressByIndex(nextIndex);
                console.log('Successfully minted NFT:');
                console.log('- Index:', nextIndex.toString());
                console.log('- Address:', nftAddress?.toString());

                // Verify NFT content
                const content = await nftCollection.getGetNftContent(nextIndex, itemContent);
                console.log('- Content verified');
            } catch (error) {
                console.log('Error verifying NFT:', error);
            }
        } else {
            console.log('Minting verification failed');
        }
    } catch (err: any) {
        console.error('Full error:', err);
    }
}
