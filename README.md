# Smart Contract Planning

TODO

- [ ] Add the property 'hidden' in the "Item" entity and migrate using:
    ```bash
    typeorm migrations:create
    ```
- [ ] **POST** will only store the address of the item contract once deployed.

- [ ] **GET** will receive the item's address and query the EVM for the item's on-chain storage data# eth-store-contract
