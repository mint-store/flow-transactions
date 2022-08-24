import LockedTokens from 0xLOCKED_TOKEN_ADDRESS

transaction(amount: UFix64) {
  let nodeDelegatorProxy: LockedTokens.LockedNodeDelegatorProxy

  prepare(acct: AuthAccount) {
    let holderRef = acct.borrow<&LockedTokens.TokenHolder>(from: LockedTokens.TokenHolderStoragePath) 
      ?? panic("TokenHolder is not saved at specified path")
    
    self.nodeDelegatorProxy = holderRef.borrowDelegator()
  }

  execute {
    self.nodeDelegatorProxy.requestUnstaking(amount: amount)
  }
}