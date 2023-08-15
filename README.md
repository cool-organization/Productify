# Productify
Upload and configure developer products with Lune!

## How to use?

If you want to use Productify, you must have [Lune](https://github.com/filiptibell/lune) installed. Once you have that done, you can create a file called `FILE_NAME.productify.toml` (you can also do `.productify.json`, `.productify.yaml`, or `.productify.yml` if you want), where `FILE_NAME` is whatever you want.

The setup for the `productify.toml` file would be:

```toml
UniverseId = 0 # The id of your universe.

[[Products]] # A sample product.
Price = 10 # The price of the product.
Name = "$50" # The name of the product.

[[Products]]
Price = 20
Name = "$100"

```

All the possible entries in the a product are as follows:

```ts
type Product = {
	Price: number,
	Name: string,
	Description: string?,

	ProductId: number?,
	UploadHash: string?,
}
```

You should ***NEVER*** add `UploadHash`, as that is calculated for you.

You can finally run it by just doing `lune/src` or whatever you may have changed the name of the folder `src` to.

## How to contribute?

Leave a pull request.

Brought to you by ping! / cool corporation.
