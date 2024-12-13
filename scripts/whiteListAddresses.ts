import { Address, toNano } from '@ton/core';
import { NftCollection } from '../wrappers/NftCollection';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    // REPLACE THIS WITH YOUR DEPLOYED NFT COLLECTION ADDRESS
    const COLLECTION_ADDRESS = Address.parse('EQD_xWbr46DyyiBDdXVUgbNkgLY9uM0hbGYf1AL1RwW1fzjF');
    
    // Predefined list of addresses to whitelist
    const WHITELIST_ADDRESSES = [
        Address.parse('EQCCOmbN2JjxQAvyXqYB6NLMcVUOikf_YVgHJFoAiESLkV-m'),
        // Address.parse('EQC-long-ton-address-2'),
    ];

    const BLACKLIST_ADDRESSES = [
        Address.parse('EQCCOmbN2JjxQAvyXqYB6NLMcVUOikf_YVgHJFoAiESLkV-m'),
    ];

    const nftCollection = provider.open(NftCollection.fromAddress(COLLECTION_ADDRESS));

    // Function to add addresses to whitelist
    async function addToWhitelist(addresses: Address[]) {
        for (const addr of addresses) {
            try {
                await nftCollection.send(
                    provider.sender(),
                    { value: toNano('0.1') },
                    {
                        $$type: 'AddToWhitelist',
                        addr: addr
                    }
                );
                console.log(`Address ${addr} added to whitelist`);
            } catch (error) {
                console.error(`Error adding address ${addr}:`, error);
            }
        }
    }

    // Function to remove addresses from whitelist
    async function removeFromWhitelist(addresses: Address[]) {
        for (const addr of addresses) {
            try {
                await nftCollection.send(
                    provider.sender(),
                    { value: toNano('0.1') },
                    {
                        $$type: 'RemoveFromWhitelist',
                        addr: addr
                    }
                );
                console.log(`Address ${addr} removed from whitelist`);
            } catch (error) {
                console.error(`Error removing address ${addr}:`, error);
            }
        }
    }

    // Function to toggle whitelist
    async function toggleWhitelist() {
        try {
            await nftCollection.send(
                provider.sender(),
                { value: toNano('0.1') },
                "ToggleWhitelist"
            );
            console.log('Whitelist toggled');
        } catch (error) {
            console.error('Error toggling whitelist:', error);
        }
    }

    // Check current whitelist status
    async function checkWhitelistStatus() {
        try {
            const isWhitelistEnabled = await nftCollection.getIsWhitelistEnabled();
            console.log('Whitelist enabled:', isWhitelistEnabled);
            return isWhitelistEnabled;
        } catch (error) {
            console.error('Error checking whitelist status:', error);
            return null;
        }
    }

    async function checkIsWhitelisted() {
        try {
            const isWhitelisted = await nftCollection.getIsWhitelisted(Address.parse('EQCCOmbN2JjxQAvyXqYB6NLMcVUOikf_YVgHJFoAiESLkV-m'));
            console.log('Is_Whitelist:', isWhitelisted);
            return isWhitelisted;
        } catch (error) {
            console.error('Error checking whitelist status:', error);
            return null;
        }
    }

    // Example usage:
    // Uncomment and modify as needed
    // await addToWhitelist(WHITELIST_ADDRESSES);
    // await removeFromWhitelist(BLACKLIST_ADDRESSES);
    // await toggleWhitelist();
    // await checkWhitelistStatus();
    await checkIsWhitelisted();
}