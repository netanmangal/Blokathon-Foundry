// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*###############################################################################

    @title GMXV2Facet
    @author Netan Mangal
    @notice Facet for GMX V2 integration - enables short positions for hedging wealth
    @dev Provides external functions to open/close shorts, manage collateral, and query positions
         This facet enables hedge fund functionality by allowing users to short assets
         for portfolio protection and risk management.

################################################################################*/

// Local Contracts
import {Facet} from "src/facets/Facet.sol";
import {GMXV2Base} from "./GMXV2Base.sol";

// Local Interfaces
import {IGMXV2} from "./IGMXV2.sol";

// Local Libraries
import {GMXV2Storage} from "./GMXV2Storage.sol";

/// @notice Thrown when caller is not authorized
error GMXV2Facet_Unauthorized();

/// @notice Thrown when invalid parameters are provided
error GMXV2Facet_InvalidParameters();

// ============================================================================
// GMXV2Facet
// ============================================================================

contract GMXV2Facet is Facet, GMXV2Base {
    // ========================================================================
    // External Functions (State-Changing)
    // ========================================================================

    /// @notice Opens a new short position on GMX V2
    /// @param params Parameters for opening the short position
    /// @return positionKey The unique identifier for the opened position
    /// @dev Only callable by diamond owner. Requires execution fee sent as msg.value
    function openShort(
        OpenShortParams calldata params
    ) external payable override onlyDiamondOwner nonReentrant returns (bytes32 positionKey) {
        return _openShort(params);
    }

    /// @notice Closes an existing short position
    /// @param params Parameters for closing the position
    /// @dev Only callable by diamond owner. Requires execution fee sent as msg.value
    function closeShort(
        CloseShortParams calldata params
    ) external payable override onlyDiamondOwner nonReentrant {
        _closeShort(params);
    }

    /// @notice Adds collateral to an existing position
    /// @param positionKey The position to add collateral to
    /// @param collateralAmount Amount of collateral to add
    /// @dev Only callable by diamond owner
    function addCollateral(
        bytes32 positionKey,
        uint256 collateralAmount
    ) external override onlyDiamondOwner nonReentrant {
        _addCollateral(positionKey, collateralAmount);
    }

    /// @notice Updates configuration parameters
    /// @param maxLeverage Maximum leverage allowed (e.g., 10 = 10x)
    /// @param minCollateralUsd Minimum collateral required in USD (30 decimals)
    /// @dev Only callable by diamond owner
    function updateConfig(
        uint256 maxLeverage,
        uint256 minCollateralUsd
    ) external override onlyDiamondOwner {
        if (maxLeverage == 0 || maxLeverage > 50) revert GMXV2Facet_InvalidParameters();
        if (minCollateralUsd == 0) revert GMXV2Facet_InvalidParameters();
        _updateConfig(maxLeverage, minCollateralUsd);
    }

    // ========================================================================
    // External Functions (View)
    // ========================================================================

    /// @notice Gets information about a specific position
    /// @param positionKey The position identifier
    /// @return position The position information struct
    function getPosition(
        bytes32 positionKey
    ) external view override returns (GMXV2Storage.PositionInfo memory position) {
        return _getPosition(positionKey);
    }

    /// @notice Gets all active positions
    /// @return positions Array of all active position information
    function getActivePositions() 
        external 
        view 
        override 
        returns (GMXV2Storage.PositionInfo[] memory positions) 
    {
        return _getActivePositions();
    }

    /// @notice Gets the current PnL for a position
    /// @param positionKey The position identifier
    /// @return pnl The profit and loss in USD (30 decimals), negative for losses
    function getPositionPnL(bytes32 positionKey) external view override returns (int256 pnl) {
        return _getPositionPnL(positionKey);
    }

    /// @notice Gets total collateral locked across all positions
    /// @return totalCollateral Total collateral in USD
    function getTotalCollateral() external view override returns (uint256 totalCollateral) {
        return _getTotalCollateral();
    }

    /// @notice Gets the number of active positions
    /// @return count Number of active positions
    function getActivePositionCount() external view override returns (uint256 count) {
        return _getActivePositionCount();
    }

    /// @notice Gets current configuration
    /// @return maxLeverage Maximum leverage allowed
    /// @return minCollateralUsd Minimum collateral required
    function getConfig() external view returns (uint256 maxLeverage, uint256 minCollateralUsd) {
        GMXV2Storage.Layout storage s = GMXV2Storage.layout();
        return (s.maxLeverage, s.minCollateralUsd);
    }

    // ========================================================================
    // Receive Function
    // ========================================================================

    /// @notice Allows contract to receive ETH (for execution fees)
    receive() external payable {}
}
