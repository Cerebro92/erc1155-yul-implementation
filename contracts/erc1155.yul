object "ERC1155" {
    code {
        // store the caller in slot zero
        sstore(0, caller())

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Protection against sending ether
            require(iszero(callvalue()))

            // Dispatcher
            switch selector()
            case 0x0e89341c /* uri(uint256) */ {
                getURI()
            }

            case 0x02fe5305 /* setURI(string) */ {
                setURI(decodeAsUint(1), decodeAsUint(2))
            }

            case 0x00fdd58e /* balanceOf(address,uint256) */ {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }

            case 0x4e1273f4 /* balanceOfBatch(address[],uint256[]) */ {
                balanceOfBatch(decodeAsUint(0), decodeAsUint(1))
            }

            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), 0x00)
            }

            case 0x1f7fdffa /* mintBatch(address,uint256[],uint256[],bytes) */ {
                mintBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), 0x00)
            }

            case 0xa22cb465 /* setApprovalForAll(address,bool) */ {
                setApprovalForAll(caller(), decodeAsUint(0), decodeAsUint(1))
            }

            case 0xe985e9c5 /* isApprovedForAll(address,address) */ {
                returnUint(isApprovedForAll(decodeAsUint(0), decodeAsUint(1)))
            }

            case 0xf242432a /* safeTransferFrom(address,address,uint256,uint256,bytes) */ {
                safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), 0x00)
            }

            case 0x2eb2c2d6 /* safeBatchTransferFrom(address,address,uint256[],uint256[],bytes) */ {
                safeBatchTransferFrom(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3), 0x00)
            }

            case 0xf5298aca /* burn(address,uint256,uint256) */ {
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }

            case 0x6b20c454 /*  burnBatch(address,uint256[],uint256[]) */ {
                burnBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }

            default {
                revert(0, 0)
            }

            function balanceOfBatch(accountsRef, idsRef) {
                let len := readAtPosition(accountsRef)
                mstore(0x100, 0x120)
                mstore(0x120, len)
                let position := 0x120
                for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                    let index := add(mul(i, 0x20), 0x20)
                    let account := readAtPosition(add(accountsRef, index))
                    let id := readAtPosition(add(idsRef, index))
                    let bal := balanceOf(account, id)
                    position := add(position, 0x20)
                    mstore(position, bal)
                }
                let endPosition := add(position, 0x20)
                return(0x100, endPosition)
            }

            function mint(to, id, amount, data) {
                addToBalance(to, id, amount)
                emitTransferSingle(caller(), 0, to, id, amount)
            }

            function mintBatch(to, idsRef, amountsRef, data) {
                let len := readAtPosition(idsRef)
                for { let i:= 0 } lt(i, len) { i := add(i, 1) } {
                    let index := add(mul(i, 0x20), 0x20)
                    let id := readAtPosition(add(idsRef, index))
                    let amount := readAtPosition(add(amountsRef, index))
                    addToBalance(to, id, amount)
                }
            }

            function safeTransferFrom(from, to, id, amount, data) {
                deductFromBalance(from, id, amount)
                addToBalance(to, id, amount)
                emitTransferSingle(caller(), from, to, id, amount)
            }

            function safeBatchTransferFrom(from, to, idsRef, amountsRef, data) {
                let len := readAtPosition(idsRef)
                for { let i:= 0 } lt(i, len) { i := add(i, 1) } {
                    let index := add(mul(i, 0x20), 0x20)
                    let id := readAtPosition(add(idsRef, index))
                    let amount := readAtPosition(add(amountsRef, index))

                    deductFromBalance(from, id, amount)
                    addToBalance(to, id, amount)
                }
            }

            function burn(from, id, amount) {
                deductFromBalance(from, id, amount)
            }

            function burnBatch(from, idsRef, amountsRef) {
                let len := readAtPosition(idsRef)
                for { let i:= 0 } lt(i, len) { i := add(i, 1) } {
                    let index := add(mul(i, 0x20), 0x20)
                    let id := readAtPosition(add(idsRef, index))
                    let amount := readAtPosition(add(amountsRef, index))
                    deductFromBalance(from, id, amount)
                }
            }

            /* calldata decoding functions */
            function selector() -> s {
                s := shr(0xe0, calldataload(0))
            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            function readAtPosition(pos) -> v {
                pos := add(4, pos)
                if lt(calldatasize(), pos) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            /* events */
            function emitTransferSingle(operator, from, to, id, value) {
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                emitEvent(signatureHash, operator, from, to, id, value)
            }

            function emitEvent(signatureHash, indexed1, indexed2, indexed3, nonIndexed1, nonIndexed2) {
                mstore(0, nonIndexed1)
                mstore(0x20, nonIndexed2)
                log4(0, 0x40, signatureHash, indexed1, indexed2, indexed3)
            }

            /* storage layout */
            function ownerPos() -> p { p := 0 }
            function uriLengthPos() -> p { p := 1}
            function uriPos() -> p { p := 2 }

            function balanceStorageOffset(id, owner) -> offset {
                mstore(0, id)
                mstore(0x20, owner)
                offset := keccak256(0, 0x40)
            }

            function approvalOffset(owner, operator) -> offset {
                mstore(0, owner)
                mstore(0x20, operator)
                offset := keccak256(0, 0x40)
            }

            /* storage access */
            function getURI() {
                mstore(0, 0x20)
                mstore(0x20, sload(uriLengthPos()))
                mstore(0x40, sload(uriPos()))
                return(0, 0x60)
            }

            function setURI(length, uri) {
                sstore(uriLengthPos(), length)
                sstore(uriPos(), uri)
            }

            function balanceOf(account, id) -> bal {
                bal := sload(balanceStorageOffset(id, account))
            }

            function setApprovalForAll(owner, operator, approved) {
                sstore(approvalOffset(owner, operator), approved)
            }

            function isApprovedForAll(account, operator) -> approved {
                approved := sload(approvalOffset(account, operator))
            }

            function addToBalance(account, id, amount) {
                let offset := balanceStorageOffset(id, account)
                sstore(offset, add(sload(offset), amount))
            }

            function deductFromBalance(account, id, amount) {
                let offset := balanceStorageOffset(id, account)
                let bal := sload(offset)
                sstore(offset, sub(bal, amount))
            }

            /* calldata encoding functions */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            /* utility functions */
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}