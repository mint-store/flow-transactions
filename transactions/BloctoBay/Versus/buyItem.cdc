import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
import NonFungibleToken from 0xNON_FUNGIBLE_TOKEN_ADDRESS
import NFTStorefront from 0xNFTStorefront_ADDRESS
import Marketplace from 0xBLOCTO_BAY_MARKETPLACE_ADDRESS
import FlowToken from 0xFLOW_TOKEN_ADDRESS
import Art from 0xVERSUS_ART_ADDRESS

transaction(listingResourceID: UInt64, storefrontAddress: Address, buyPrice: UFix64) {
    let paymentVault: @FungibleToken.Vault
    let artCollection: &Art.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(signer: AuthAccount) {
        // Create a collection to store the purchase if none present
        if signer.borrow<&Art.Collection>(from: Art.CollectionStoragePath) == nil {
            signer.save(<-Art.createEmptyCollection(), to: Art.CollectionStoragePath)
            signer.link<&Art.Collection{Art.CollectionPublic, NonFungibleToken.CollectionPublic}>(
                Art.CollectionPublicPath,
                target: Art.CollectionStoragePath
            )
        }

        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")
        let price = self.listing.getDetails().salePrice

        assert(buyPrice == price, message: "buyPrice is NOT same with salePrice")

        let flowTokenVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from signer storage")
        self.paymentVault <- flowTokenVault.withdraw(amount: price)

        self.artCollection = signer.borrow<&Art.Collection{NonFungibleToken.Receiver}>(from: Art.CollectionStoragePath)
            ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        let item <- self.listing.purchase(payment: <-self.paymentVault)

        self.artCollection.deposit(token: <-item)

        // Be kind and recycle
        self.storefront.cleanup(listingResourceID: listingResourceID)
        Marketplace.removeListing(id: listingResourceID)
    }

}