// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Book} from "../src/book.sol";

contract BookTest is Test {
    Book public book;
    
    address public owner;
    address public alice;
    address public bob;
    
    string public constant BASE_URI = "https://asasdosilencio.novatrix.tech/metadata/";
    uint256 public constant EDITION_MULTIPLIER = 1_000_000;

    event BookMinted(address indexed to, uint256 indexed edition, uint256 indexed item);
    event BookBatchMinted(address indexed to, uint256[] editions, uint256[] items);
    event TokenURISet(uint256 indexed tokenId, string uri);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        vm.prank(owner);
        book = new Book(owner, BASE_URI);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(book.owner(), owner);
    }

    function test_Constructor_SetsBaseURI() public view {
        assertEq(book.baseURI(), BASE_URI);
    }

    function test_Constructor_EditionMultiplier() public view {
        assertEq(book.EDITION_MULTIPLIER(), EDITION_MULTIPLIER);
    }

    // ============ Token ID Encoding/Decoding Tests ============

    function test_EncodeTokenId_Edition1Item1() public view {
        uint256 tokenId = book.encodeTokenId(1, 1);
        assertEq(tokenId, 1_000_001);
    }

    function test_EncodeTokenId_Edition1Item999999() public view {
        uint256 tokenId = book.encodeTokenId(1, 999_999);
        assertEq(tokenId, 1_999_999);
    }

    function test_EncodeTokenId_Edition100Item500() public view {
        uint256 tokenId = book.encodeTokenId(100, 500);
        assertEq(tokenId, 100_000_500);
    }

    function test_EncodeTokenId_RevertsWhenItemTooLarge() public {
        vm.expectRevert("Item number too large");
        book.encodeTokenId(1, EDITION_MULTIPLIER);
    }

    function test_DecodeTokenId_Edition1Item1() public view {
        (uint256 edition, uint256 item) = book.decodeTokenId(1_000_001);
        assertEq(edition, 1);
        assertEq(item, 1);
    }

    function test_DecodeTokenId_Edition100Item500() public view {
        (uint256 edition, uint256 item) = book.decodeTokenId(100_000_500);
        assertEq(edition, 100);
        assertEq(item, 500);
    }

    function test_EncodeDecodeTokenId_Roundtrip(uint256 edition, uint256 item) public view {
        vm.assume(item < EDITION_MULTIPLIER);
        vm.assume(edition < type(uint256).max / EDITION_MULTIPLIER);
        
        uint256 tokenId = book.encodeTokenId(edition, item);
        (uint256 decodedEdition, uint256 decodedItem) = book.decodeTokenId(tokenId);
        
        assertEq(decodedEdition, edition);
        assertEq(decodedItem, item);
    }

    // ============ URI Tests ============

    function test_Uri_ReturnsCorrectFormat() public view {
        uint256 tokenId = book.encodeTokenId(1, 1);
        string memory expectedUri = string(abi.encodePacked(BASE_URI, "1000001.json"));
        assertEq(book.uri(tokenId), expectedUri);
    }

    function test_BookURI_ReturnsCorrectFormat() public view {
        string memory expectedUri = string(abi.encodePacked(BASE_URI, "1000001.json"));
        assertEq(book.bookURI(1, 1), expectedUri);
    }

    function test_Uri_ReturnsCustomURIWhenSet() public {
        uint256 tokenId = book.encodeTokenId(1, 1);
        string memory customUri = "ipfs://QmCustomHash/1000001.json";
        
        vm.prank(owner);
        book.setTokenURI(tokenId, customUri);
        
        assertEq(book.uri(tokenId), customUri);
    }

    function test_SetBaseURI_UpdatesBaseURI() public {
        string memory newBaseUri = "https://new-domain.com/metadata/";
        
        vm.prank(owner);
        book.setBaseURI(newBaseUri);
        
        assertEq(book.baseURI(), newBaseUri);
    }

    function test_SetBaseURI_RevertsWhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        book.setBaseURI("https://hacker.com/");
    }

    function test_SetTokenURI_ByTokenId() public {
        uint256 tokenId = book.encodeTokenId(1, 1);
        string memory customUri = "ipfs://QmCustomHash/special.json";
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokenURISet(tokenId, customUri);
        book.setTokenURI(tokenId, customUri);
        
        assertEq(book.uri(tokenId), customUri);
    }

    function test_SetTokenURI_ByEditionAndItem() public {
        uint256 edition = 2;
        uint256 item = 50;
        uint256 tokenId = book.encodeTokenId(edition, item);
        string memory customUri = "ipfs://QmAnotherHash/edition2.json";
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokenURISet(tokenId, customUri);
        book.setTokenURI(edition, item, customUri);
        
        assertEq(book.uri(tokenId), customUri);
    }

    function test_SetTokenURI_RevertsWhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        book.setTokenURI(1_000_001, "ipfs://hack");
    }

    // ============ Mint Tests ============

    function test_Mint_MintsToRecipient() public {
        uint256 edition = 1;
        uint256 item = 1;
        uint256 tokenId = book.encodeTokenId(edition, item);
        
        vm.prank(owner);
        book.mint(alice, edition, item);
        
        assertEq(book.balanceOf(alice, tokenId), 1);
    }

    function test_Mint_EmitsBookMintedEvent() public {
        uint256 edition = 1;
        uint256 item = 1;
        
        vm.prank(owner);
        vm.expectEmit(true, true, true, false);
        emit BookMinted(alice, edition, item);
        book.mint(alice, edition, item);
    }

    function test_Mint_EmitsTokenURISetEvent() public {
        uint256 edition = 1;
        uint256 item = 1;
        uint256 tokenId = book.encodeTokenId(edition, item);
        string memory expectedUri = string(abi.encodePacked(BASE_URI, "1000001.json"));
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokenURISet(tokenId, expectedUri);
        book.mint(alice, edition, item);
    }

    function test_Mint_SetsTokenURI() public {
        uint256 edition = 1;
        uint256 item = 1;
        uint256 tokenId = book.encodeTokenId(edition, item);
        
        vm.prank(owner);
        book.mint(alice, edition, item);
        
        string memory expectedUri = string(abi.encodePacked(BASE_URI, "1000001.json"));
        assertEq(book.uri(tokenId), expectedUri);
    }

    function test_Mint_RevertsWhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        book.mint(alice, 1, 1);
    }

    function test_Mint_RevertsWhenItemTooLarge() public {
        vm.prank(owner);
        vm.expectRevert("Item number too large");
        book.mint(alice, 1, EDITION_MULTIPLIER);
    }

    function test_Mint_MultipleDifferentTokens() public {
        vm.startPrank(owner);
        book.mint(alice, 1, 1);
        book.mint(alice, 1, 2);
        book.mint(bob, 2, 1);
        vm.stopPrank();
        
        assertEq(book.balanceOf(alice, book.encodeTokenId(1, 1)), 1);
        assertEq(book.balanceOf(alice, book.encodeTokenId(1, 2)), 1);
        assertEq(book.balanceOf(bob, book.encodeTokenId(2, 1)), 1);
    }

    // ============ MintBatch Tests ============

    function test_MintBatch_MintsMultipleTokens() public {
        uint256[] memory editions = new uint256[](3);
        uint256[] memory items = new uint256[](3);
        
        editions[0] = 1; items[0] = 1;
        editions[1] = 1; items[1] = 2;
        editions[2] = 2; items[2] = 1;
        
        vm.prank(owner);
        book.mintBatch(alice, editions, items);
        
        assertEq(book.balanceOf(alice, book.encodeTokenId(1, 1)), 1);
        assertEq(book.balanceOf(alice, book.encodeTokenId(1, 2)), 1);
        assertEq(book.balanceOf(alice, book.encodeTokenId(2, 1)), 1);
    }

    function test_MintBatch_EmitsBookBatchMintedEvent() public {
        uint256[] memory editions = new uint256[](2);
        uint256[] memory items = new uint256[](2);
        
        editions[0] = 1; items[0] = 1;
        editions[1] = 1; items[1] = 2;
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit BookBatchMinted(alice, editions, items);
        book.mintBatch(alice, editions, items);
    }

    function test_MintBatch_SetsTokenURIs() public {
        uint256[] memory editions = new uint256[](2);
        uint256[] memory items = new uint256[](2);
        
        editions[0] = 1; items[0] = 1;
        editions[1] = 2; items[1] = 50;
        
        vm.prank(owner);
        book.mintBatch(alice, editions, items);
        
        string memory expectedUri1 = string(abi.encodePacked(BASE_URI, "1000001.json"));
        string memory expectedUri2 = string(abi.encodePacked(BASE_URI, "2000050.json"));
        
        assertEq(book.uri(book.encodeTokenId(1, 1)), expectedUri1);
        assertEq(book.uri(book.encodeTokenId(2, 50)), expectedUri2);
    }

    function test_MintBatch_RevertsWhenLengthMismatch() public {
        uint256[] memory editions = new uint256[](2);
        uint256[] memory items = new uint256[](3);
        
        editions[0] = 1; editions[1] = 2;
        items[0] = 1; items[1] = 2; items[2] = 3;
        
        vm.prank(owner);
        vm.expectRevert("Length mismatch");
        book.mintBatch(alice, editions, items);
    }

    function test_MintBatch_RevertsWhenNotOwner() public {
        uint256[] memory editions = new uint256[](1);
        uint256[] memory items = new uint256[](1);
        editions[0] = 1; items[0] = 1;
        
        vm.prank(alice);
        vm.expectRevert();
        book.mintBatch(alice, editions, items);
    }

    function test_MintBatch_RevertsWhenItemTooLarge() public {
        uint256[] memory editions = new uint256[](2);
        uint256[] memory items = new uint256[](2);
        
        editions[0] = 1; items[0] = 1;
        editions[1] = 1; items[1] = EDITION_MULTIPLIER;
        
        vm.prank(owner);
        vm.expectRevert("Item number too large");
        book.mintBatch(alice, editions, items);
    }

    // ============ ERC1155 Transfer Tests ============

    function test_SafeTransferFrom_TransfersToken() public {
        uint256 tokenId = book.encodeTokenId(1, 1);
        
        vm.prank(owner);
        book.mint(alice, 1, 1);
        
        vm.prank(alice);
        book.safeTransferFrom(alice, bob, tokenId, 1, "");
        
        assertEq(book.balanceOf(alice, tokenId), 0);
        assertEq(book.balanceOf(bob, tokenId), 1);
    }

    function test_SafeBatchTransferFrom_TransfersMultipleTokens() public {
        uint256[] memory editions = new uint256[](2);
        uint256[] memory items = new uint256[](2);
        editions[0] = 1; items[0] = 1;
        editions[1] = 1; items[1] = 2;
        
        vm.prank(owner);
        book.mintBatch(alice, editions, items);
        
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        tokenIds[0] = book.encodeTokenId(1, 1);
        tokenIds[1] = book.encodeTokenId(1, 2);
        amounts[0] = 1;
        amounts[1] = 1;
        
        vm.prank(alice);
        book.safeBatchTransferFrom(alice, bob, tokenIds, amounts, "");
        
        assertEq(book.balanceOf(bob, tokenIds[0]), 1);
        assertEq(book.balanceOf(bob, tokenIds[1]), 1);
    }

    // ============ Approval Tests ============

    function test_SetApprovalForAll_AllowsOperator() public {
        vm.prank(owner);
        book.mint(alice, 1, 1);
        
        vm.prank(alice);
        book.setApprovalForAll(bob, true);
        
        assertTrue(book.isApprovedForAll(alice, bob));
    }

    function test_ApprovedOperator_CanTransfer() public {
        uint256 tokenId = book.encodeTokenId(1, 1);
        
        vm.prank(owner);
        book.mint(alice, 1, 1);
        
        vm.prank(alice);
        book.setApprovalForAll(bob, true);
        
        vm.prank(bob);
        book.safeTransferFrom(alice, bob, tokenId, 1, "");
        
        assertEq(book.balanceOf(bob, tokenId), 1);
    }

    // ============ Edge Case Tests ============

    function test_Mint_Edition0Item0() public {
        vm.prank(owner);
        book.mint(alice, 0, 0);
        
        assertEq(book.balanceOf(alice, 0), 1);
    }

    function test_Uri_LargeTokenId() public view {
        uint256 edition = 1000;
        uint256 item = 999999;
        uint256 tokenId = book.encodeTokenId(edition, item);
        
        string memory expectedUri = string(abi.encodePacked(BASE_URI, "1000999999.json"));
        assertEq(book.uri(tokenId), expectedUri);
    }

    function test_BalanceOfBatch() public {
        vm.startPrank(owner);
        book.mint(alice, 1, 1);
        book.mint(alice, 1, 2);
        book.mint(bob, 2, 1);
        vm.stopPrank();
        
        address[] memory accounts = new address[](3);
        uint256[] memory tokenIds = new uint256[](3);
        
        accounts[0] = alice;
        accounts[1] = alice;
        accounts[2] = bob;
        
        tokenIds[0] = book.encodeTokenId(1, 1);
        tokenIds[1] = book.encodeTokenId(1, 2);
        tokenIds[2] = book.encodeTokenId(2, 1);
        
        uint256[] memory balances = book.balanceOfBatch(accounts, tokenIds);
        
        assertEq(balances[0], 1);
        assertEq(balances[1], 1);
        assertEq(balances[2], 1);
    }

    // ============ Ownership Transfer Tests ============

    function test_TransferOwnership() public {
        vm.prank(owner);
        book.transferOwnership(alice);
        
        assertEq(book.owner(), alice);
    }

    function test_NewOwner_CanMint() public {
        vm.prank(owner);
        book.transferOwnership(alice);
        
        vm.prank(alice);
        book.mint(bob, 1, 1);
        
        assertEq(book.balanceOf(bob, book.encodeTokenId(1, 1)), 1);
    }

    function test_OldOwner_CannotMintAfterTransfer() public {
        vm.prank(owner);
        book.transferOwnership(alice);
        
        vm.prank(owner);
        vm.expectRevert();
        book.mint(bob, 1, 1);
    }

    function test_RenounceOwnership() public {
        vm.prank(owner);
        book.renounceOwnership();
        
        assertEq(book.owner(), address(0));
    }
}
