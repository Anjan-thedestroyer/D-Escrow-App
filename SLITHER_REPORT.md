**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [assembly](#assembly) (9 results) (Informational)
 - [solc-version](#solc-version) (1 results) (Informational)
 - [low-level-calls](#low-level-calls) (1 results) (Informational)
 - [naming-convention](#naming-convention) (15 results) (Informational)
## assembly
Impact: Informational
Confidence: High
 - [ ] ID-0
[StorageSlot.getStringSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L105-L111) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L109-L111)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L105-L111


 - [ ] ID-1
[StorageSlot.getStringSlot(string)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L115-L120) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L118-L120)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L115-L120


 - [ ] ID-2
[StorageSlot.getInt256Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L97-L102) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L101-L102)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L97-L102


 - [ ] ID-3
[StorageSlot.getBytesSlot(bytes)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L131-L138) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L136-L138)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L131-L138


 - [ ] ID-4
[StorageSlot.getBooleanSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L73-L76) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L75)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L73-L76


 - [ ] ID-5
[StorageSlot.getBytesSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L122-L129) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L127-L129)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L122-L129


 - [ ] ID-6
[StorageSlot.getAddressSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L64-L67) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L66-L67)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L64-L67


 - [ ] ID-7
[StorageSlot.getUint256Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L90-L93) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L93)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L90-L93


 - [ ] ID-8
[StorageSlot.getBytes32Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L82-L84) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L84)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L82-L84


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-9
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](lib/openzeppelin-contracts/contracts/access/Ownable.sol#L2-L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Context.sol#L2-L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L2-L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L3-L5)
	- [^0.8.20](src/Escrow.sol#L1-L2)

lib/openzeppelin-contracts/contracts/access/Ownable.sol#L2-L4


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-10
Low level call in [Escrow.withdraw()](src/Escrow.sol#L70-L81):
	- [(success,None) = address(msg.sender).call{value: amount}()](src/Escrow.sol#L77-L79)

src/Escrow.sol#L70-L81


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-11
Parameter [Escrow.completeMilestone(uint256,uint256)._dealId](src/Escrow.sol#L119-L121) is not in mixedCase

src/Escrow.sol#L119-L121


 - [ ] ID-12
Parameter [Escrow.resolveDispute(uint256,uint256,uint256)._payeeAmount](src/Escrow.sol#L175-L178) is not in mixedCase

src/Escrow.sol#L175-L178


 - [ ] ID-13
Parameter [Escrow.getMilestones(uint256)._dealId](src/Escrow.sol#L218) is not in mixedCase

src/Escrow.sol#L218


 - [ ] ID-14
Parameter [Escrow.createDeal(address,string[],uint256[])._amount](src/Escrow.sol#L86-L87) is not in mixedCase

src/Escrow.sol#L86-L87


 - [ ] ID-15
Parameter [Escrow.raisedDispute(uint256,string)._dealId](src/Escrow.sol#L160) is not in mixedCase

src/Escrow.sol#L160


 - [ ] ID-16
Parameter [Escrow.createDeal(address,string[],uint256[])._description](src/Escrow.sol#L83-L86) is not in mixedCase

src/Escrow.sol#L83-L86


 - [ ] ID-17
Parameter [Escrow.getFullDealsByUser(address)._user](src/Escrow.sol#L229) is not in mixedCase

src/Escrow.sol#L229


 - [ ] ID-18
Parameter [Escrow.resolveDispute(uint256,uint256,uint256)._payerAmount](src/Escrow.sol#L174-L175) is not in mixedCase

src/Escrow.sol#L174-L175


 - [ ] ID-19
Parameter [Escrow.createDeal(address,string[],uint256[])._payee](src/Escrow.sol#L83) is not in mixedCase

src/Escrow.sol#L83


 - [ ] ID-20
Parameter [Escrow.completeDeal(uint256)._dealId](src/Escrow.sol#L142) is not in mixedCase

src/Escrow.sol#L142


 - [ ] ID-21
Parameter [Escrow.resolveDispute(uint256,uint256,uint256)._dealId](src/Escrow.sol#L174) is not in mixedCase

src/Escrow.sol#L174


 - [ ] ID-22
Parameter [Escrow.raisedDispute(uint256,string)._reason](src/Escrow.sol#L160) is not in mixedCase

src/Escrow.sol#L160


 - [ ] ID-23
Parameter [Escrow.getDeal(uint256)._dealId](src/Escrow.sol#L213) is not in mixedCase

src/Escrow.sol#L213


 - [ ] ID-24
Parameter [Escrow.cancelDeal(uint256)._dealId](src/Escrow.sol#L195-L196) is not in mixedCase

src/Escrow.sol#L195-L196


 - [ ] ID-25
Parameter [Escrow.completeMilestone(uint256,uint256)._milestoneId](src/Escrow.sol#L121) is not in mixedCase

src/Escrow.sol#L121


