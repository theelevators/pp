
using namespace System.Windows.Forms
using namespace System.Drawing

$productsWindow = {

    $Server = "SERVER"
    $Database = "DATABASE"
    $conn = "Server=$Server;Database=$Database;Trusted_Connection=True" 

    $query = "SELECT * FROM ITEMS"
    $name = "ITEMS"
    $size = New-Object System.Drawing.Size(600, 800)
    $window = [QueryWindow]::new($name, $query, $conn, $size)
    $onRowUpdate = {
        Param([DataGridViewCellEventArgs] $e, [System.Windows.Forms.DataGridView] $dataGrid)
    
        $ridx = $e.RowIndex
            
        
        $id = $dataGrid.Rows[$ridx].Cells[0].Value
        $item = $dataGrid.Rows[$ridx].Cells[3].Value
       
        $query = "UPDATE ITEMS SET NAME = '$item' WHERE ID = $id"
        $Connection = New-Object System.Data.SQLClient.SQLConnection  
        $Connection.ConnectionString = $conn
        $Connection.Open()  
        $command = new-object system.data.sqlclient.sqlcommand($query, $connection)
    
        $command.ExecuteNonQuery()
    
        $connection.Close()
    
    
    }
    
    $window.SetRowUpdate($script)
    
    return $window
}
    
$customerWindow = {
    
    $Server = "SERVER"
    $Database = "DATABASE"
    $conn = "Server=$Server;Database=$Database;Trusted_Connection=True" 

    $query = "SELECT * FROM CUSTOMERS "
    $name = "CUSTOMERS Table"
    $size = New-Object System.Drawing.Size(600, 800)
    
    $window = [QueryWindow]::new($name, $query, $conn, $size)
    
    
    return $window
}

