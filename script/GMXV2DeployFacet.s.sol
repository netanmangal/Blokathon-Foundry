//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "script/Base.s.sol";
import {console} from "forge-std/console.sol";
import {DiamondCutFacet} from "src/facets/baseFacets/cut/DiamondCutFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {GMXV2Facet} from "src/facets/utilityFacets/gmxV2/GMXV2Facet.sol";

contract GMXV2DeployFacetScript is BaseScript {
    address internal constant DIAMOND_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    function run() public broadcaster {
        setUp();
        
        // Deploy GMXV2Facet
        GMXV2Facet gmxV2Facet = new GMXV2Facet();

        // Add GMXV2Facet to diamond
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);

        // Add function selectors to GMXV2Facet
        bytes4[] memory functionSelectors = new bytes4[](10);
        functionSelectors[0] = GMXV2Facet.openShort.selector;
        functionSelectors[1] = GMXV2Facet.closeShort.selector;
        functionSelectors[2] = GMXV2Facet.addCollateral.selector;
        functionSelectors[3] = GMXV2Facet.getPosition.selector;
        functionSelectors[4] = GMXV2Facet.getActivePositions.selector;
        functionSelectors[5] = GMXV2Facet.getPositionPnL.selector;
        functionSelectors[6] = GMXV2Facet.getTotalCollateral.selector;
        functionSelectors[7] = GMXV2Facet.getActivePositionCount.selector;
        functionSelectors[8] = GMXV2Facet.updateConfig.selector;
        functionSelectors[9] = GMXV2Facet.getConfig.selector;

        // Add GMXV2Facet to diamond
        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(gmxV2Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Cut diamond
        DiamondCutFacet(DIAMOND_ADDRESS).diamondCut(facetCuts, address(0), "");
        console.log("GMXV2Facet deployed to: ", address(gmxV2Facet));
    }
}
