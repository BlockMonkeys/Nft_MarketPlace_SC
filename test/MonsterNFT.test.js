const { expect } = require("chai");
const { ethers } = require("hardhat");
const abi = require("../artifacts/contracts/MonsterNFT.sol/MonsterNFT.json").abi;

describe("MonsterNFT", function () {
  let bob, alice, trudy;
  const iface = new ethers.utils.Interface(abi);

  beforeEach(async () => {
    [bob, alice, trudy] = await ethers.getSigners();
    const nftContract_artifact = await ethers.getContractFactory("MonsterNFT", bob);
    this.nftContract = await nftContract_artifact.deploy();
  })

  it("Check Deploy", async () => {
    const nameOfNFT = await this.nftContract.name();
    expect(nameOfNFT).to.be.eq("Monster");
  });

  it("[Feat : Redeem NFT] Alice Buy BoB`s Lazyminting NFT", async () => {
    const oneEther = await ethers.utils.parseEther("1").toString();
    const voucher = ["Test Name", "Test Description", "https://testIpfs.io", oneEther];

    const before_alice_balance_bn = await ethers.provider.getBalance(alice.address);
    const before_alice_balance_ether = await ethers.utils.formatEther(before_alice_balance_bn);
    const before_bob_balance_bn = await ethers.provider.getBalance(bob.address);
    const before_bob_balance_ether = await ethers.utils.formatEther(before_bob_balance_bn);
    const before_nft_balanceOf_alice = await this.nftContract.balanceOf(alice.address);

    //1. Create Msg Hash of Voucher;
    const msgHash = await this.nftContract.getMsgHash(voucher);

    //2. Sign (GET PERSONAL SIGN DATA);
    const personalSign = await bob.signMessage(ethers.utils.arrayify(msgHash));

    //3. RedeemNFT
    await this.nftContract.connect(alice).redeemNFT(
                                            alice.address, 
                                            bob.address, 
                                            personalSign, 
                                            voucher,
                                            { 
                                              value : oneEther 
                                            }
                                          );
    
    
    const after_alice_balance_bn = await ethers.provider.getBalance(alice.address);
    const after_alice_balance_ether = await ethers.utils.formatEther(after_alice_balance_bn);

    const after_bob_balance_bn = await ethers.provider.getBalance(bob.address);
    const after_bob_balance_ether = await ethers.utils.formatEther(after_bob_balance_bn);
    const after_nft_balanceOf_alice = await this.nftContract.balanceOf(alice.address);
    
    // @ NFT Transfer Check;
    expect(Number(after_nft_balanceOf_alice.toString())).to.be.gt(Number(before_nft_balanceOf_alice.toString()));
    // @ Alice Balance Check;
    expect(Number(after_alice_balance_ether.toString())).to.be.lt(Number(before_alice_balance_ether.toString()));
    // @ Bob Balance Check;                                       
    expect(Number(after_bob_balance_ether.toString())).to.be.gt(Number(before_bob_balance_ether.toString()));
  })

  it("[Feat : Mint NFT] Minting NFT", async () => {
    const testNftName = "TestNFT";
    const testDescription = "TestNFTDescription";
    const testIpfsUrl = "https://testIpfs.io"

    const tx = await this.nftContract.connect(bob).mintNFT(testNftName, testDescription, testIpfsUrl);
    const decoded = iface.parseTransaction({ data : tx.data });

    // @ NFT Check;
    expect(decoded.args._name).to.be.eq(testNftName);
    expect(decoded.args._description).to.be.eq(testDescription);
    expect(decoded.args._url).to.be.eq(testIpfsUrl);
  })

  it("[Feat : Set Price ] Set Price & Mint NFT", async () => {
    // @ Set Price;
    const price = await ethers.utils.parseEther("1").toString();

    const before_getprice_tx = await this.nftContract.mintingPrice();
    await this.nftContract.connect(bob).setPrice(price);
    const after_getprice_tx = await this.nftContract.mintingPrice();

    expect(before_getprice_tx.toString()).to.be.eq("0");
    expect(after_getprice_tx.toString()).to.be.eq(price);

    // @ Minting After Set Price;
    const before_alice_balance_bn = await ethers.provider.getBalance(alice.address);
    const before_alice_balance_ether = await ethers.utils.formatEther(before_alice_balance_bn);

    const before_bob_balance_bn = await ethers.provider.getBalance(bob.address);
    const before_bob_balance_ether = await ethers.utils.formatEther(before_bob_balance_bn);

    // @ Mitning
    await this.nftContract.connect(alice)
                          .mintNFT("TEST", "TESTD", "www.testIpfs.io",
                          {
                            value : price
                          }
                        );
    
    const after_alice_balance_bn = await ethers.provider.getBalance(alice.address);
    const after_alice_balance_ether = await ethers.utils.formatEther(after_alice_balance_bn);  
    const after_bob_balance_bn = await ethers.provider.getBalance(bob.address);
    const after_bob_balance_ether = await ethers.utils.formatEther(after_bob_balance_bn);

    // @ Transfer Coin Check;
    expect(Number(after_alice_balance_ether)).to.be.lt(Number(before_alice_balance_ether));
    expect(Number(after_bob_balance_ether)).to.be.gt(Number(before_bob_balance_ether));
  })

  it("[Feat : Lock Contract] Set Lock The Contract", async () => {
    await this.nftContract.connect(bob).setLocking();

    // @ Call Mint NFT
    expect(this.nftContract.connect(alice).mintNFT("TEST", "TEST", "TEST"))
      .to.be.revertedWith("ERR : Currently Locked");

    // @ Call Redeem NFT
    const oneEther = await ethers.utils.parseEther("1").toString();
    const voucher = ["Test Name", "Test Description", "https://testIpfs.io", oneEther];
    const msgHash = await this.nftContract.getMsgHash(voucher);
    const personalSign = await bob.signMessage(ethers.utils.arrayify(msgHash));
    
    expect(this.nftContract.connect(alice).redeemNFT(alice.address, bob.address, personalSign, voucher, { value : oneEther }))
      .to.be.revertedWith("ERR : Currently Locked")
  })

  it("[Feat : Change Owner] Change Contract Owner", async () => {
    const currentOwner = await this.nftContract.owner();

    expect(currentOwner).to.be.eq(bob.address);
    expect(this.nftContract.connect(alice).changeOwner(alice.address)).to.be.revertedWith("ERR : Not Authorized");
    
    await this.nftContract.connect(bob).changeOwner(alice.address);

    const newOwner = await this.nftContract.owner();
    expect(newOwner).to.be.eq(alice.address);
  })

  it("[Feat : Emergency] emergencyWithdrawal Function", async () => {
    // @ Exception check;
    expect(this.nftContract.connect(alice).emergencyWithdrawal()).to.be.revertedWith("Not Authorized");

    // @ Init Balance;
    const before_bob_balnce = await ethers.provider.getBalance(bob.address);
    const before_bob_balnce_ether = await ethers.utils.formatEther(before_bob_balnce);
    
    // @ Send Ether Into CA;
    await alice.sendTransaction({
      to: this.nftContract.address,
      value: ethers.utils.parseEther("1.0")
    });

    const after_CA_balance = await this.nftContract.connect(bob).checkBalance();
    expect(after_CA_balance).to.be.eq(ethers.utils.parseEther("1.0"));

    // @ After Withdraw Balance;
    await this.nftContract.connect(bob).emergencyWithdrawal();

    const after_bob_balnce = await ethers.provider.getBalance(bob.address);
    const after_bob_balnce_ether = await ethers.utils.formatEther(after_bob_balnce);
    const afterWithdraw_CA_balance = await this.nftContract.connect(bob).checkBalance();

    console.log(`after_bob_balnce_ether : ${after_bob_balnce_ether}`);
    console.log(`afterWithdraw_CA_balance : ${afterWithdraw_CA_balance}`);

    // Is BOB received Coin ?
    expect(Number(after_bob_balnce_ether)).to.be.gt(Number(before_bob_balnce_ether));
    // Is CA Empty ?
    expect(Number(afterWithdraw_CA_balance)).to.be.eq(0);
  });


  it("[Feat : Emergency] emergencyWithdrawal_transfer", async () => {
    // @ Exception check;
    expect(this.nftContract.connect(alice).emergencyWithdrawal()).to.be.revertedWith("Not Authorized");

    // @ Send Ether Into CA;
    await alice.sendTransaction({
      to: this.nftContract.address,
      value: ethers.utils.parseEther("1.0")
    });

    const before_trudy_balance = await ethers.provider.getBalance(trudy.address);
    const before_trudy_balance_before_ether = await ethers.utils.formatEther(before_trudy_balance);

    // @ After Withdraw Balance;
    await this.nftContract.connect(bob).emergencyWithdrawal_transfer(trudy.address, ethers.utils.parseEther("1.0"));

    const after_trudy_balance = await ethers.provider.getBalance(trudy.address);
    const after_trudy_balance_ether = await ethers.utils.formatEther(after_trudy_balance);

    expect(after_trudy_balance_ether).to.be.gt(before_trudy_balance_before_ether);
  })
});
