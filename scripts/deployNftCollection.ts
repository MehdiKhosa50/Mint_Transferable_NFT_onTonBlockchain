import { Address, beginCell, fromNano, toNano } from '@ton/core';
import { NftCollection } from '../wrappers/NftCollection';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const OFFCHAIN_CONTENT_PREFIX = 0x01;
    
    // This will point to your collection.json in the uploaded folder
    const COLLECTION_CONTENT_URL = `https://brown-left-fowl-93.mypinata.cloud/ipfs/bafkreifacnpwwwywsry77xvnlarikptm3lofy3sfi44jhh4uun5rnb7agu?pinataGatewayToken=Pt9ebBt6Lq3lboPVJtZkbiteF2O28CNqM4fGuundgLYRfwydZqhbduu-EGIj-H0A`;
    
    const NFT_PRICE = toNano('0.5');
    
    console.log('Using collection metadata URL:', COLLECTION_CONTENT_URL);
    
    const contentCell = beginCell()
        .storeInt(OFFCHAIN_CONTENT_PREFIX, 8)
        .storeStringRefTail(COLLECTION_CONTENT_URL)
        .endCell();

    const owner = provider.sender().address;

    if (!owner) {
        console.log("Owner address is undefined");
        return;
    }

    const nftCollection = provider.open(await NftCollection.fromInit(owner, contentCell, NFT_PRICE, true));

    console.log('NFT collection will be deployed at:', nftCollection.address);

    await nftCollection.send(
        provider.sender(),
        {
            value: toNano('0.3') + NFT_PRICE,
        },
        "Mint"
    );

    await provider.waitForDeploy(nftCollection.address);

    console.log('NFT Collection deployed');

    const collectionData = await nftCollection.getGetCollectionData();
    console.log('Collection data:', collectionData);

    const latestIndexId = collectionData.next_item_index;
    console.log("Latest indexID:", latestIndexId);

    const itemAddress = await nftCollection.getGetNftAddressByIndex(latestIndexId - 1n);
    console.log('Minted NFT Item address:', itemAddress);
    
    // Log the URLs for verification
    console.log('\nImportant URLs:');
    console.log('Collection Metadata:', COLLECTION_CONTENT_URL);
    // console.log('NFT Item Metadata:', `https://gateway.pinata.cloud/ipfs/${IPFS_CID}/item.json`);
}