pragma solidity 0.4.19;

import "./Ownable.sol";
import "./BurnableToken.sol";

contract WePoolToken is BurnableToken, Ownable {

    string public constant name = "WePool";
    string public constant symbol = "WPL";
    uint32 public constant decimals = 18;

    function WePoolToken() public {
        totalSupply = 200000000 * 1E18; // 200 million tokens
        balances[owner] = totalSupply;  // owner is crowdsale
    }
}
