// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DebtConverter.sol";

contract DebtConverterTest is Test {
    DebtConverter converter;

    address user = address(0x001);

    function setUp() public {
        converter = new DebtConverter(
            100,
            address(0x2222),
            address(0x3333),
            address(0x4444),
            address(0x5555)
        );





        /**
         * @notice Direct initialization of the conversions array via its storage slot.
         *Because the test targets  is another function, this approach was used.
         */

         //conversions slot number
        uint256 conversionsSlot = 13;

        // Compute the storage slot for conversions[user].length
        bytes32 arraySlot = keccak256(
            abi.encode(user, conversionsSlot)
        );

        // Manually set conversions[user].length = 3
        // Valid indices are: 0, 1, 2
        vm.store(
            address(converter),
            arraySlot,
            bytes32(uint256(3))
        );
    }





    function test_out_of_bounds_panic() public {
        vm.prank(user);

        /**
         * @notice Index 3 =  conversions[user].length.
         *         The `if`  check in redeemConversion() only checks `> length`
         *        ــ allowing this value to pass.
         *
         * @dev Accessing conversions[user][3] triggers an EVM
         *      "index out of bounds" panic instead of the intended
         *      ConversionDoesNotExist revert.
         */


        /// @BUG 
        /// panic  error is NOT related to the `if`condition
        /// because the `if` check is bypassed.
        /// The error originates from this line of function:  -------->  ConversionData storage c = conversions[msg.sender][_conversion];
        vm.expectRevert();
        converter.redeemConversion(3, 0);
    }
}
