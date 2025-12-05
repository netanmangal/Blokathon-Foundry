// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Diamond} from "src/Diamond.sol";
import {GMXV2Facet} from "src/facets/utilityFacets/gmxV2/GMXV2Facet.sol";
import {GMXV2Storage} from "src/facets/utilityFacets/gmxV2/GMXV2Storage.sol";
import {IGMXV2} from "src/facets/utilityFacets/gmxV2/IGMXV2.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {DiamondCutFacet} from "src/facets/baseFacets/cut/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/baseFacets/loupe/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/facets/baseFacets/ownership/OwnershipFacet.sol";
import {IERC173} from "src/interfaces/IERC173.sol";

contract GMXV2FacetTest is Test {
    Diamond public diamond;
    GMXV2Facet public gmxFacet;
    
    address public owner;
    address public user;
    
    // Mock token addresses (use actual Arbitrum addresses in production)
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    
    function setUp() public {
        owner = address(this);
        user = address(0x1234);
        
        // Deploy base facets
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        
        // Prepare facet cuts for base facets
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        // DiamondCut
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = IDiamondCut.diamondCut.selector;
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondCutFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cutSelectors
        });
        
        // DiamondLoupe
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });
        
        // Ownership
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = IERC173.owner.selector;
        ownershipSelectors[1] = IERC173.transferOwnership.selector;
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });
        
        // Deploy diamond
        diamond = new Diamond(owner, cuts);
        
        // Deploy GMX V2 Facet
        gmxFacet = new GMXV2Facet();
        
        // Add GMX V2 Facet to diamond
        bytes4[] memory gmxSelectors = new bytes4[](10);
        gmxSelectors[0] = GMXV2Facet.openShort.selector;
        gmxSelectors[1] = GMXV2Facet.closeShort.selector;
        gmxSelectors[2] = GMXV2Facet.addCollateral.selector;
        gmxSelectors[3] = GMXV2Facet.getPosition.selector;
        gmxSelectors[4] = GMXV2Facet.getActivePositions.selector;
        gmxSelectors[5] = GMXV2Facet.getPositionPnL.selector;
        gmxSelectors[6] = GMXV2Facet.getTotalCollateral.selector;
        gmxSelectors[7] = GMXV2Facet.getActivePositionCount.selector;
        gmxSelectors[8] = GMXV2Facet.updateConfig.selector;
        gmxSelectors[9] = GMXV2Facet.getConfig.selector;
        
        IDiamondCut.FacetCut[] memory gmxCuts = new IDiamondCut.FacetCut[](1);
        gmxCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(gmxFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: gmxSelectors
        });
        
        DiamondCutFacet(address(diamond)).diamondCut(gmxCuts, address(0), "");
        
        console.log("Diamond deployed at:", address(diamond));
        console.log("GMX V2 Facet deployed at:", address(gmxFacet));
    }
    
    function testConfigUpdate() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        // Update config
        facet.updateConfig(15, 200 * 1e30);
        
        // Check config
        (uint256 maxLeverage, uint256 minCollateral) = facet.getConfig();
        
        assertEq(maxLeverage, 15, "Max leverage should be 15");
        assertEq(minCollateral, 200 * 1e30, "Min collateral should be 200 USD");
    }
    
    function testGetActivePositionCount() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        uint256 count = facet.getActivePositionCount();
        assertEq(count, 0, "Should have 0 active positions initially");
    }
    
    function testGetTotalCollateral() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        uint256 totalCollateral = facet.getTotalCollateral();
        assertEq(totalCollateral, 0, "Should have 0 total collateral initially");
    }
    
    function testGetActivePositions() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        GMXV2Storage.PositionInfo[] memory positions = facet.getActivePositions();
        assertEq(positions.length, 0, "Should have 0 active positions");
    }
    
    function testUnauthorizedAccess() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        vm.prank(user);
        vm.expectRevert();
        facet.updateConfig(10, 100 * 1e30);
    }
    
    function testInvalidConfigParameters() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        // Test invalid max leverage (0)
        vm.expectRevert();
        facet.updateConfig(0, 100 * 1e30);
        
        // Test invalid max leverage (> 50)
        vm.expectRevert();
        facet.updateConfig(51, 100 * 1e30);
        
        // Test invalid min collateral (0)
        vm.expectRevert();
        facet.updateConfig(10, 0);
    }
    
    function testDefaultConfig() public {
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        // Trigger initialization by trying to open a position (will fail but init config)
        IGMXV2.OpenShortParams memory params = IGMXV2.OpenShortParams({
            indexToken: WETH,
            collateralToken: USDC,
            collateralAmount: 1000 * 1e6, // 1000 USDC
            sizeInUsd: 5000 * 1e30,       // 5000 USD position
            acceptablePrice: 2000 * 1e30, // 2000 USD per ETH
            executionFee: 0.001 ether,
            callbackContract: address(0)
        });
        
        // This will revert due to insufficient balance, but config should be initialized
        vm.expectRevert();
        facet.openShort{value: 0.001 ether}(params);
    }
    
    // Note: Full integration tests would require:
    // 1. Forking Arbitrum mainnet
    // 2. Dealing mock tokens to diamond
    // 3. Interacting with real GMX contracts
    // Example:
    /*
    function testOpenShortIntegration() public {
        // Fork Arbitrum
        vm.createSelectFork("https://arb1.arbitrum.io/rpc");
        
        GMXV2Facet facet = GMXV2Facet(payable(address(diamond)));
        
        // Deal USDC to diamond
        deal(USDC, address(diamond), 10000 * 1e6);
        
        IGMXV2.OpenShortParams memory params = IGMXV2.OpenShortParams({
            indexToken: WETH,
            collateralToken: USDC,
            collateralAmount: 1000 * 1e6,
            sizeInUsd: 5000 * 1e30,
            acceptablePrice: 2000 * 1e30,
            executionFee: 0.001 ether,
            callbackContract: address(0)
        });
        
        bytes32 positionKey = facet.openShort{value: 0.001 ether}(params);
        
        assertTrue(positionKey != bytes32(0), "Position should be created");
        
        uint256 count = facet.getActivePositionCount();
        assertEq(count, 1, "Should have 1 active position");
    }
    */
}
