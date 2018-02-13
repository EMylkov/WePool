pragma solidity 0.4.19;

import "./Ownable.sol";
import "./WePoolToken.sol";


contract WePoolCrowdsale is Ownable {
    using SafeMath for uint256;


    uint256 public hardCap;
    uint256 public reserved;

    uint256 public tokensSold; // amount of bought tokens
    uint256 public weiRaised; // total investments
    uint256 private weiLeft; // money for withdrawal

    uint256 public minPurchase;
    uint256 public preIcoRate; // how many token units a buyer gets per wei
    uint256 public icoRate;

    address public wallet; // for withdrawal
    address public tokenWallet; // for reserving tokens

    uint256 public icoStartTime;
    uint256 public preIcoStartTime;


    address[] public investorsArray;
    mapping (address => uint256) public investors; //address -> amount


    WePoolToken public token;
     
    modifier icoEnded() {
        require(now > (icoStartTime + 30 days));
        _;        
    }

    /**
     * @dev Constructor to WePoolCrowdsale contract
     */
    function WePoolCrowdsale(uint256 _preIcoStartTime, uint256 _icoStartTime) public {
        
        preIcoStartTime = _preIcoStartTime;
        icoStartTime = _icoStartTime;

        minPurchase = 0.1 ether;
        preIcoRate = 0.00008 ether;
        icoRate = 0.0001 ether;

        hardCap = 200000000 * 1E18; // 200 million tokens * decimals

        token = new WePoolToken();

        reserved = hardCap.mul(25).div(100);
        hardCap = hardCap.sub(reserved); // tokens left for sale (200m - 50m = 150m)

        wallet = owner;
        tokenWallet = owner;
    }

    /**
     * @dev Function set new wallet address. Wallet is used for withdrawal
     * @param newWallet Address of new wallet.
     */
    function changeWallet(address newWallet) public onlyOwner {
        require(newWallet != address(0));
        wallet = newWallet;
    }

    /**
     * @dev Function set new token wallet address
     * @dev Token wallet is used for reserving tokens for founders
     * @param newAddress Address of new Token Wallet
     */
    function changeTokenWallet(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        require(reserved > 0);
        tokenWallet = newAddress;
    }

    /**
     * @dev Function set new preIco start time
     * @param newTime New preIco start time
     */
    function changePreIcoStartTime(uint256 newTime) public onlyOwner {
        require(now < preIcoStartTime);
        preIcoStartTime = newTime;
    }

    /**
     * @dev Function set new Ico start time
     * @param newTime New Ico start time
     */
    function changeIcoStartTime(uint256 newTime) public onlyOwner {
        require(now < icoStartTime);
        icoStartTime = newTime;
    }

    /**
     * @dev Function burn all unsold Tokens (balance of crowdsale)
     * @dev Ico should be ended
     */
    function burnUnsoldtokens() public onlyOwner icoEnded {
        token.burn(token.balanceOf(this));
    }

    /**
     * @dev Function transfer all raised money to the founders wallet
     * @dev Ico should be ended
     */
    function withdrawal() public onlyOwner icoEnded {
        require(weiLeft > 0);

        uint256 amount = weiLeft;
        weiLeft = 0;
        wallet.transfer(amount);    
    }

    /**
     * @dev Function reserve tokens for founders and bounty program
     * @dev Ico should be ended
     */
    function getReservedTokens() public onlyOwner icoEnded {
        require(reserved > 0);
        uint256 amount = reserved;
        reserved = 0;
        token.transfer(tokenWallet, amount);
    }

    /**
     * @dev Fallback function
     */
    function() public payable {
        buyTokens();
    }

    /**
     * @dev Function for investments.
     */
    function buyTokens() public payable {
        address inv = msg.sender;
        require(inv != address(0));
        
        uint256 weiAmount = msg.value;
        require(weiAmount >= minPurchase);

        uint256 rate;
        uint256 tokens;
        uint256 cleanWei; // amount of wei to use for purchase excluding change and hardcap overflows
        uint256 change;

        if (now > preIcoStartTime && now < (preIcoStartTime + 7 days)) {
            rate = preIcoRate;
        } else if (now > icoStartTime && now < (icoStartTime + 30 days)) {
            rate = icoRate;
        }
        require(rate > 0);
    
        tokens = (weiAmount.mul(1E18)).div(rate);

        // check hardCap
        if (tokensSold.add(tokens) > hardCap) {
            tokens = hardCap.sub(tokensSold);
            cleanWei = tokens.mul(rate).div(1E18);
            change = weiAmount.sub(cleanWei);
        } else {
            cleanWei = weiAmount;
        }

        // check, if this investor already included
        if (investors[inv] == 0) {
            investorsArray.push(inv);
            investors[inv] = tokens;
        } else {
            investors[inv] = investors[inv].add(tokens);
        }

        tokensSold = tokensSold.add(tokens);
        weiRaised = weiRaised.add(cleanWei);
        weiLeft = weiLeft.add(cleanWei);

        token.transfer(inv, tokens);

        /*// add investment to history
        history.push(Transaction(inv, cleanWei, now)); */


        // send back change
        if (change > 0) {
            inv.transfer(change); 
        }
    }

    /**
     * @dev Function returns the number of investors.
     * @return uint256 Number of investors.
     */
    function getInvestorsLength() public view returns(uint256) {
        return investorsArray.length;
    }
}
