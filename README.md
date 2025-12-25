![Result](https://raw.githubusercontent.com/AidenNabavi/inverse/main/result.png)


## Audit Report
Project:`Inverse Finance`  
Researcher:`Aiden`
Date:🎄`2025/12/26`

---



## Title 

**Incomplete if  condition Implementation Leading to Unexpected EVM Panic (Out-of-Bounds)**
---

##  Report Type

`Smart Contract`   
`Lending`  
`On-chain`   
`Staking`  
`Finance Protocol`  


---

##  Target 
-  `Debt Repayments - Debt Converter` 

- `Address`:  https://etherscan.io/address/0x1ff9c712b011cbf05b67a6850281b13ca27ecb2a

- `Asset`: DebtConverter.sol 

- `Affected Functions`:  redeemConversion() 


---
## Rating

Severity: `Low`

Impact: `Low`

Likelihood:`Medium` 

Attack Complexity :`None`


---
## Analysis

- ``Preconditions for the bug:``none  
- ``Bug triggered by:``any external user  
- ``Amount at risk:``none 
- ``Who is affected (users, protocol, etc.):`protocol    
- ``Impact:`` 
what the developer intended was  incompletely implemented due to a syntax mistake.
It bypasses the if condition   and causes an unexpected Panic error to occur.(out of band)
It makes the UI behave unpredictably.

---
## Description

In the `redeemConversion` function, the array boundary check is not performed correctly.
The index validation only reverts for values  greater than  the array length, but **allows the case where the index is equal to the array length**, bypassing the `if` condition check.
As a result, accessing the array triggers an **out-of-bounds EVM panic revert** instead of a graceful revert.


**Vulnerability**
 in this function 

 ```solidity

     function redeemConversion(uint _conversion, uint _endEpoch) public {
        if (_conversion > conversions[msg.sender].length) revert ConversionDoesNotExist();
        accrueInterest();
        ConversionData storage c = conversions[msg.sender][_conversion];
        uint lastEpochRedeemed = c.lastEpochRedeemed;
     
     ...
     }
 ```
``The purpose of this condition is to prevent inputs outside the array index range, but an invalid index input is still allowed.``
**Step by Step**
example: 
Assume the following state:
```solidity
conversions[msg.sender].length == 3
```


Valid indices are:
```solidity
0, 1, 2
```


Now the user calls:
```solidity
redeemConversion(3, 0);
```


in this condition 
```solidity
if (_conversion > conversions[msg.sender].length)revert ConversionDoesNotExist();
//3 > 3   false --> by pass
```
Because the condition only checks for `>` instead of `>=` the validation does not revert when _conversion is equal to the array length.




Out-of-bounds array access occurs
```solidity
ConversionData storage c = conversions[msg.sender][_conversion]; // conversions[msg.sender][3] 

```

---
##  Vulnerability Details

 core issue is in the `if` statement:
using `>` instead of `>=`


```solidity
    function redeemConversion(uint _conversion, uint _endEpoch) public {
        if (_conversion > conversions[msg.sender].length) revert ConversionDoesNotExist();
        accrueInterest();
        ConversionData storage c = conversions[msg.sender][_conversion];


    ...
    }

```

---
## How to fix it (Recommended)

Array bounds checking must be performed correctly:
 in this function ---->redeemConversion()

 replace
 ```solidity
if (_conversion >= conversions[msg.sender].length)revert ConversionDoesNotExist();

```

with
  
```solidity
if (_conversion > conversions[msg.sender].length) revert ConversionDoesNotExist();
```
---

##  References
-  `Debt Repayments - Debt Converter` 

- `Address`:  https://etherscan.io/address/0x1ff9c712b011cbf05b67a6850281b13ca27ecb2a

- `Asset`: DebtConverter.sol 

- `Affected Functions`:  redeemConversion() 

---
##  Proof of Concept (PoC)


for run test download from github 👇🏽
``

**Step by Step**



```solidity 
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



```








