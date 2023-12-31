--!optimize 2
--!strict
local HashLib = require("../Packages/HashLib")
local serde = require("@lune/serde")
local t = require("../Packages/t")

local ProductifyUtilities = {}

export type ProductEntry = {
	Name: string,
	Price: number,
	Description: string?,
	ProductId: number?,
	UploadHash: string?,
}
ProductifyUtilities.IsProductEntry = t.strictInterface({
	Name = t.string;
	Price = t.integer;
	Description = t.optional(t.string);
	ProductId = t.optional(t.integer);
	UploadHash = t.optional(t.string);
})

export type GamePassEntry = {
	Name: string,
	Price: number,
	Description: string?,
	GamePassId: number?,
	UploadHash: string?,
}
ProductifyUtilities.IsGamePassEntry = t.strictInterface({
	Name = t.string;
	Price = t.integer;
	Description = t.optional(t.string);
	GamePassId = t.optional(t.integer);
	UploadHash = t.optional(t.string);
})

export type Productify = {
	UniverseId: number,
	Products: {ProductEntry},
	GamePasses: {GamePassEntry}?,
}
ProductifyUtilities.IsProductify = t.strictInterface({
	UniverseId = t.integer;
	Products = t.array(ProductifyUtilities.IsProductEntry);
	GamePasses = t.optional(t.array(ProductifyUtilities.IsGamePassEntry));
})

export type AnyProductEntry = ProductEntry | GamePassEntry

function ProductifyUtilities.GetHash(ProductEntry: AnyProductEntry)
	return HashLib.base64_encode(HashLib.sha1(serde.encode("json", {
		Description = ProductEntry.Description;
		Name = ProductEntry.Name;
		Price = ProductEntry.Price;
		ProductId = (ProductEntry :: ProductEntry).ProductId or (ProductEntry :: GamePassEntry).GamePassId;
	} :: {any}, false)))
end

assert(ProductifyUtilities.GetHash({
	Name = "test";
	Price = 100;
	Description = "test";
	ProductId = 1;
	UploadHash = "test";
}) == ProductifyUtilities.GetHash({
	UploadHash = "test";
	Name = "test";
	Description = "test";
	ProductId = 1;
	Price = 100;
}), "Failed to check equality for GetHash?")

function ProductifyUtilities.IsProductEntryOutdated(ProductEntry: AnyProductEntry)
	if
		(not (ProductEntry :: ProductEntry).ProductId and not (ProductEntry :: GamePassEntry).GamePassId)
		or ProductEntry.UploadHash == nil
	then
		return true
	end

	return ProductifyUtilities.GetHash(ProductEntry) ~= ProductEntry.UploadHash
end

return table.freeze(ProductifyUtilities)
