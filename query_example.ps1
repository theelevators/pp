.$PSScriptRoot/util/window.ps1
.$PSScriptRoot/queries.ps1


$assigned = $assignWindow.invoke()
$assigned.Display()

$products = $productsWindow.invoke()

$products.Display()

