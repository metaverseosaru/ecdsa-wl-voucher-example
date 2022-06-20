// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract VaucherTestMultiple is Ownable {

    // mintSigner address 
    address public mintSigner = 0x05ac4b63D504A528C0952d07dCA024DB50138830;    
    // uint256 to boolean Map. This saves gas compared to bytes32 to Boolean Mapping.
    BitMaps.BitMap internal usedVaucher; 

    // Invalid signature error
    error InvalidSignature();

    // Validate multiple vauchers
    modifier validateVauchers(bytes[] memory signatures, uint256[] memory ticketNumbers) {
        // Get # of tickets received.
        uint arraylength = ticketNumbers.length;
        for (uint i=0; i<arraylength; i++){
            // Getting the message hash based on abi.encodePacked.
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender(), ticketNumbers[i]));
            // Validating the vaucher.
            if (!SignatureChecker.isValidSignatureNow(mintSigner, messageHash, signatures[i])) {
                revert InvalidSignature();
            }
        }
        _;
    }

    // See if ticketes were already used. All of the tickets need to be unused to pass this check.
    modifier checkUsedVauchers(uint256[] memory ticketNumbers) {
        // Iterate through ticketes and check.
        uint arraylength = ticketNumbers.length;
        for (uint i=0; i<arraylength; i++){
            require(!(BitMaps.get(usedVaucher, ticketNumbers[i])), "Vaucher already used");
        }
        _;
    }

    // Check if vauchers were used.
    function getUsedVauchers(uint256[] memory ticketNumbers) external view returns(bool[] memory)
    {
        uint arraylength = ticketNumbers.length;
        bool[] memory output = new bool[](arraylength);
        for (uint i=0; i<arraylength; i++){
            output[i] = BitMaps.get(usedVaucher, ticketNumbers[i]);
        }
        return output;
    }

    // Claim tickets
    function claimTicketBitMap(bytes[] memory signatures, uint256[] memory ticketNumbers)
    external 
    validateVauchers(signatures, ticketNumbers)
    checkUsedVauchers(ticketNumbers)
    {
        uint arraylength = ticketNumbers.length;
        for (uint i=0; i<arraylength; i++){
            BitMaps.setTo(usedVaucher, ticketNumbers[i], true);
        }
    }

    // Get multiple messages
    function getMessageHash(uint256[] memory ticketNumbers) external view returns (bytes32[] memory){
        uint arraylength = ticketNumbers.length;
        bytes32[] memory output = new bytes32[](arraylength);
        for (uint i=0; i<arraylength; i++){
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender(), ticketNumbers[i]));
            output[i] = messageHash;
        }
        return output;
    }
}
