.$PSScriptRoot/util/window.ps1
.$PSScriptRoot/queries.ps1


$products = $productsWindow.invoke()
$products.Display()

$customers = $customersWindow.invoke()

$customers.Display()

