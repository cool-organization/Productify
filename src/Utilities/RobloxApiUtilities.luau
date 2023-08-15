--!optimize 2
--!strict
local Debug = require("../Packages/Debug")
local HttpUtilities = require("./HttpUtilities")
local Promise = require("../Packages/PromiseTyped")
local SerdeUtilities = require("./SerdeUtilities")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local t = require("../Packages/t")

local RobloxApiUtilities = {}

local XsrfCache: {[string]: string} = {}

function RobloxApiUtilities.ClearCache()
	table.clear(XsrfCache)
end

type IsoTimestamp = string

export type UploadResponse = {
	id: number,
	name: string,
	Description: string, -- ???
	shopId: number,
	iconImageAssetId: number?,
}

export type DeveloperProductInfo = {
	affiliateFeePercentage: number?,
	assetCategories: number,
	assetGenres: number,
	assetTypeId: number?,
	created: IsoTimestamp,
	creatorId: number,
	id: number,
	isForSale: boolean,
	isNew: boolean,
	isPublicDomain: boolean,
	premiumPriceInRobux: number?,
	priceInRobux: number,
	productTypeId: number,
	robloxProductId: number?,
	targetId: number,
	updated: IsoTimestamp,
}

local function ReturnId(ProductInfo: DeveloperProductInfo)
	if type(ProductInfo) == "table" and type(ProductInfo.id) == "number" then
		return ProductInfo.id
	end

	error(`What? - {type(ProductInfo)}`)
end

local function PromiseXsrf(): Promise.TypedPromise<string>
	local Cookie = roblox.getAuthCookie(false)
	if not Cookie then
		return Promise.Reject("Failed to get cookie?")
	end

	if XsrfCache[Cookie] then
		return Promise.Resolve(XsrfCache[Cookie])
	end

	return (HttpUtilities.PromiseRequest({
		Headers = {
			cookie = Cookie;
			["content-type"] = "application/json;charset=utf-8";
		};
		Method = "POST";
		Url = "https://auth.roblox.com/v2/login";
	}, true) :: any):Then(function(ResponseDictionary)
		local Xsrf = ResponseDictionary.Headers["x-csrf-token"]
		XsrfCache[Cookie] = Xsrf
		return Xsrf
	end)
end

local function PromiseSignedInHeaders(): Promise.TypedPromise<{[string]: string}>
	return (PromiseXsrf() :: any):Then(function(Xsrf)
		local Cookie = roblox.getAuthCookie(false)
		assert(Cookie, "Failed to get cookie (after getting Xsrf?)")
		return {
			["x-csrf-token"] = Xsrf;
			cookie = Cookie;
		}
	end)
end

local PRODUCT_URL =
	"https://apis.roblox.com/developer-products/v1/universes/%*/developerproducts?name=%*&description=%*&priceInRobux=%*"

local PublishProductTuple = t.tuple(t.integer, t.string, t.integer, t.optional(t.string))

local function PromisePublishProduct(
	UniverseId: number,
	ProductName: string,
	PriceInRobux: number,
	Description: string?
): Promise.TypedPromise<string>
	local TypeSuccess, TypeError = PublishProductTuple(UniverseId, ProductName, PriceInRobux, Description)
	if not TypeSuccess then
		return Promise.Reject(TypeError)
	end

	return PromiseSignedInHeaders():Then(function(Headers)
		return HttpUtilities.PromiseRequest({
			Headers = Headers;
			Method = "POST";
			Url = string.format(PRODUCT_URL, UniverseId, ProductName, Description or "", PriceInRobux);
		}, true)
	end):Then(HttpUtilities.ReturnBody)
end

local function GetId(Response: UploadResponse | string | number)
	if type(Response) == "number" then
		return Response
	elseif type(Response) == "table" then
		assert(type(Response.id) == "number", "Invalid response type.")
		return Response.id
	elseif type(Response) == "string" then
		local NewResponse = serde.decode("json", Response)
		assert(type(NewResponse.id) == "number", "Invalid response type.")
		return NewResponse.id
	else
		error(`Invalid argument #1 to 'GetId' (UploadResponse or string or number expected, got {typeof(Response)})`)
	end
end

local function DecodeProductInfoBody(Body: string)
	return HttpUtilities.PromiseDecode(Body, {} :: DeveloperProductInfo)
end

local function PromiseProductInfoFromUpload(
	Response: UploadResponse | string | number
): Promise.TypedPromise<DeveloperProductInfo>
	return (PromiseSignedInHeaders() :: any):Then(function(Headers)
		local Id = GetId(Response)
		return HttpUtilities.PromiseRequest({
			Headers = Headers;
			Method = "GET";
			Url = `https://apis.roblox.com/developer-products/v1/developer-products/{Id}`;
		})
	end):Then(HttpUtilities.ReturnBody):Then(DecodeProductInfoBody)
end

local UpdateProductTuple = t.tuple(t.integer, t.integer, t.string, t.integer, t.optional(t.string))
function RobloxApiUtilities.PromiseUpdateProduct(
	UniverseId: number,
	ProductId: number,
	ProductName: string,
	PriceInRobux: number,
	Description: string?
): Promise.TypedPromise<string>
	local TypeSuccess, TypeError = UpdateProductTuple(UniverseId, ProductId, ProductName, PriceInRobux, Description)
	if not TypeSuccess then
		return Promise.Reject(TypeError)
	end

	return SerdeUtilities.PromiseEncode("json", {
		Description = Description or "";
		Name = ProductName;
		PriceInRobux = PriceInRobux;
	}, false):Then(function(Body)
		return PromiseSignedInHeaders():Then(function(Headers)
			local NewHeaders = table.clone(Headers)
			NewHeaders["content-type"] = "application/json-patch+json"

			return HttpUtilities.PromiseRequest({
				Body = Body;
				Headers = NewHeaders;
				Method = "POST";
				Url = `https://apis.roblox.com/developer-products/v1/universes/{UniverseId}/developerproducts/{ProductId}/update`;
			}, false)
		end)
	end):Then(HttpUtilities.ReturnBody)
end

local function PromiseProductIdFromName(UniverseId: number, ProductName: string): Promise.TypedPromise<number>
	return PromiseSignedInHeaders():Then(function(Headers)
		return HttpUtilities.PromiseRequest({
			Headers = Headers;
			Method = "GET";
			Url = `https://apis.roblox.com/developer-products/v1/universes/{UniverseId}/developerproducts?pageNumber=1&pageSize=100`;
		})
	end):Then(HttpUtilities.ReturnBody):Then(HttpUtilities.PromiseDecode):Then(function(Products: {UploadResponse})
		for _, Product in Products do
			if Product.name == ProductName then
				return Product
			end
		end

		return Promise.Reject(`Failed to find product with name "{ProductName}".`)
	end):Then(PromiseProductInfoFromUpload):Then(ReturnId)
end

function RobloxApiUtilities.GetAllDeveloperProducts(UniverseId: number): Promise.TypedPromise<
	{DeveloperProductInfo & {description: string, name: string}}
>
	return PromiseSignedInHeaders():Then(function(Headers)
		return HttpUtilities.PromiseRequest({
			Headers = Headers;
			Method = "GET";
			Url = `https://apis.roblox.com/developer-products/v1/universes/{UniverseId}/developerproducts?pageNumber=1&pageSize=100`;
		})
	end):Then(HttpUtilities.ReturnBody):Then(HttpUtilities.PromiseDecode):Then(function(Products: {UploadResponse})
		local Promises = {}
		for Index, Product in Products do
			Promises[Index] = PromiseProductInfoFromUpload(Product):Then(function(ProductInfo)
				local New: any = table.clone(ProductInfo)
				New.description = Product.Description
				New.name = Product.name
				return New
			end)
		end

		return Promise.All(Promises)
	end)
end

function RobloxApiUtilities.PromiseGuaranteedProductUpload(
	UniverseId: number,
	ProductName: string,
	PriceInRobux: number,
	Description: string?
)
	return (PromisePublishProduct(UniverseId, ProductName, PriceInRobux, Description) :: any):Then(
		HttpUtilities.PromiseDecode
	):Then(function(ResponseTable)
		local ErrorCode = ResponseTable.errorCode
		if ErrorCode then
			if ErrorCode == "DuplicateProductName" then
				return PromiseProductIdFromName(UniverseId, ProductName):Then(function(ProductId)
					return RobloxApiUtilities.PromiseUpdateProduct(
						UniverseId,
						ProductId,
						ProductName,
						PriceInRobux,
						Description
					):ThenReturn(ProductId)
				end)
			end

			return Promise.Reject(
				`Failed to publish product - {ErrorCode} ({Debug.TableToString(ResponseTable :: any, true, "ResponseTable")})` -- have to cast this or else the next usage errors? thanks luau 👍
			)
		end

		return PromiseProductInfoFromUpload(ResponseTable):Then(ReturnId)
	end)
end

return table.freeze(RobloxApiUtilities)
