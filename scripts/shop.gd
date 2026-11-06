class_name Shop
## A town merchant's purse and shelves (mechanics reference: NPC shops track supply and demand,
## pay less for what they have plenty of, refuse overstocked items, run out of gold until they
## restock, and prices differ by town so hauling goods between towns pays).

const BASE_CASH := 400            # gold a merchant starts each restock with
const RESTOCK_SECONDS := 120.0    # every so often the purse refills and the shelves sell down
const OVERSTOCK := 15             # holding this many of something, the merchant won't buy more

var town := ""
var buy_factor := 1.0             # what this town pays for goods (remote towns pay more)
var sell_factor := 1.0            # what this town charges for supplies
var cash := BASE_CASH
var stock := {}                   # item id -> how many the merchant is holding
var _timer := RESTOCK_SECONDS


func _init(p_town: String, p_buy: float, p_sell: float) -> void:
	town = p_town
	buy_factor = p_buy
	sell_factor = p_sell


## What the merchant would pay for one more of `id` right now; 0 means it won't buy.
func offer(id: String) -> int:
	var have := int(stock.get(id, 0))
	if have >= OVERSTOCK:
		return 0
	var price := maxi(1, roundi(float(Items.value(id)) * buy_factor / (1.0 + have / 5.0)))
	return price if price <= cash else 0


func buy_from_player(id: String) -> int:
	var price := offer(id)
	if price > 0:
		cash -= price
		stock[id] = int(stock.get(id, 0)) + 1
	return price


## This town's price for a supply whose base price is `base`.
func price(base: int) -> int:
	return maxi(1, roundi(base * sell_factor))


## Gold paid to the merchant for supplies goes into its purse.
func take_payment(amount: int) -> void:
	cash += amount


func tick(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = RESTOCK_SECONDS
	cash = maxi(cash, BASE_CASH)
	for id in stock.keys():
		stock[id] = floori(int(stock[id]) * 0.6)   # goods sold on to other customers
		if int(stock[id]) <= 0:
			stock.erase(id)
