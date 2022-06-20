// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract VaucherTest is Ownable {

    // mintSigner address 
    address public mintSigner = 0x76b2Dc39d7502304Db763D036ED9aa046Dd36A5d;    
    // uint256 to boolean Map. This saves gas compared to bytes32 to Boolean Mapping.
    BitMaps.BitMap internal usedVaucher; 

    // This is the basic most crude implementation of BitMaps.BitMap.
    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256[3] arr = [MAX_INT, MAX_INT, MAX_INT];

    // Invalid signature error
    error InvalidSignature();

    // Voucher validator
    modifier validateVaucher(bytes memory signature, uint256 ticketNumber) {
        // Getting the message hash based on abi.encodePacked.
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender(), ticketNumber));
        // Validating the vaucher.
        if (!SignatureChecker.isValidSignatureNow(mintSigner, messageHash, signature)) {
            revert InvalidSignature();
        }
        _;
    }

    function getMessageHash(uint256 ticketNumber) external view returns (bytes32){
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender(), ticketNumber));
        return messageHash;
    }
    
    function claimTicketBitMap(bytes memory signature, uint256 ticketNumber)
    external 
    validateVaucher(signature, ticketNumber)
    {
        // Check bitmap to see if the ticket was already used (good if it is false).
        require(!(BitMaps.get(usedVaucher, ticketNumber)), "already taken");
        // Set ticket number ot be used (true).
        BitMaps.setTo(usedVaucher, ticketNumber, true);
    }

    function claimTicketRaw(bytes memory signature, uint256 ticketNumber)
    external 
    validateVaucher(signature, ticketNumber)
    {
        // check if ticket is good (bit of 1)
        require(ticketNumber < arr.length * 256, "too large");
        uint256 storageOffset = ticketNumber / 256;
        uint256 offsetWithin256 = ticketNumber % 256;
        uint256 storedBit = (arr[storageOffset] >> offsetWithin256) & uint256(1);
        require(storedBit == 1, "already taken");
 
        // Assign bit of 0 to already used ticket. 
        arr[storageOffset] = arr[storageOffset] & ~(uint256(1) << offsetWithin256);
    }
}
