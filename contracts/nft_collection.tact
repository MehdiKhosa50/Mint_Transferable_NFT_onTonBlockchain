const minTonsForStorage: Int = ton("0.05");
const gasConsumption: Int = ton("0.05");

contract NftCollection {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    collection_content: Cell;
    nft_price: Int;
    whitelist_enabled: Bool;
    whitelisted_addresses: map<Address, Bool>; // Declare the map here

    init(owner_address: Address, collection_content: Cell, nft_price: Int, whitelist_enabled: Bool) {
        self.owner_address = owner_address;
        self.collection_content = collection_content;
        self.nft_price = nft_price;
        self.whitelist_enabled = whitelist_enabled;
        // No need to initialize whitelisted_addresses; it's empty by default
    }

    // Add address to whitelist
    receive(msg: AddToWhitelist) {
        require(sender() == self.owner_address, "Only owner can modify whitelist");
        self.whitelisted_addresses.set(msg.addr, true);
    }

    // Remove address from whitelist
    receive(msg: RemoveFromWhitelist) {
        require(sender() == self.owner_address, "Only owner can modify whitelist");
        self.whitelisted_addresses.set(msg.addr, false); // Remove entry by setting it to null
    }

    // Toggle whitelist functionality
    receive("ToggleWhitelist") {
        require(sender() == self.owner_address, "Only owner can toggle whitelist");
        self.whitelist_enabled = !self.whitelist_enabled;
    }

    // Modified Mint function with whitelist check
    receive("Mint") {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        // Check whitelist if enabled
        if (self.whitelist_enabled) {
            require(self.whitelisted_addresses.exists(ctx.sender), "Address not whitelisted");
        }

        let totalCost: Int = self.get_nft_mint_total_cost();
        require(msgValue >= totalCost, "Insufficient funds for minting");

        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption + self.nft_price);

        // Send NFT price to owner
        if (self.nft_price > 0) {
            send(SendParameters{
                to: self.owner_address,
                value: self.nft_price,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "NFT Sale".asComment()
            });
        }

        self.mint(ctx.sender, msgValue);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    // Add getter for whitelist status
    get fun is_whitelisted(address: Address): Bool {
        return self.whitelisted_addresses.exists(address);
    }

    get fun is_whitelist_enabled(): Bool {
        return self.whitelist_enabled;
    }

    receive("Withdraw") {
        require(sender() == self.owner_address, "Only owner can withdraw");
        let withdrawAmount: Int = myBalance() - context().value - minTonsForStorage;
        require(withdrawAmount > 0, "No TON to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: withdrawAmount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "Non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msgValue, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.owner_address,
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    // --------- Get Collection Metadata Function --------- //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_nft_mint_total_cost(): Int {
        return (minTonsForStorage + gasConsumption + self.nft_price);
    }

    get fun get_nft_address_by_index(item_index: Int): Address? {      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "Not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
    let ctx: Context = context(); 
    let msgValue: Int = self.msgValue(ctx.value);
    
    if (self.is_initialized == false) {  // Initial Transfer (Minting)
        require(ctx.sender == self.collection_address, "Not authorized for initial transfer");
        self.is_initialized = true;
        self.owner = msg.new_owner;
        self.individual_content = msg.custom_payload;
        if (msgValue > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
    } else {  // Regular Transfer
        require(ctx.sender == self.owner, "Not authorized for transfer");
        
        let old_owner: Address = self.owner!!;
        self.owner = msg.new_owner;
        
        // Notify the old owner (response destination)
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                mode: 64, // Return unused value
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
        
        // Notify the new owner
        send(SendParameters{
            to: msg.new_owner,
            value: msgValue,
            mode: SendPayGasSeparately,
            body: OwnershipAssigned{
                query_id: msg.query_id,
                prev_owner: old_owner,
                forward_payload: msg.forward_payload
            }.toCell()
        });
    }
}

    receive(msg: GetStaticData){ 
        send(SendParameters {
            to: sender(),
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    receive("Destroy") {
        require(sender() == self.owner, "Not owner");
        self.owner = null;
        let excess: Int = myBalance() - context().value - minTonsForStorage;

        if (excess > 0) {
            send(SendParameters{
                to: sender(),
                bounce: false,
                value: excess,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Item Metadata Function --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append("item.json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }
}

// Keep only the necessary messages and structs
message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

message AddToWhitelist {
    addr: Address;
}

message RemoveFromWhitelist {
    addr: Address;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}