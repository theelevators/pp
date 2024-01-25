

using namespace System.Windows.Forms
using namespace System.Drawing


class QueryWindow {
    [System.Windows.Forms.Form] $window;    
    [string] $name;
    [string] $query;
    [string] $conn;
    [string] $viewFilter;
    [ScriptBlock] $rowUpdate;
    [System.Data.DataTable] $dt;
    [System.Drawing.Size] $size;
    [System.Windows.Forms.DataGridView] $dataGrid;
    [System.Windows.Forms.DataGridView] $filterGrid;
    [System.Data.DataView] $currView;
    
    QueryWindow([string] $name, [string]$query, [string] $conn, [System.Drawing.Size] $size) {


        $this.name = $name
        $this.query = $query
        $this.conn = $conn
        $this.size = $size
        $this.viewFilter = ""
        
    }

    [void] SetViewFilter([string] $filter) {
        if ($this.viewFilter -eq "") {
           
            $this.viewFilter = $filter
        }
        else {
           
            $this.viewFilter = -join ($this.viewFilter, " AND ", $filter)

        }
    
    }

    [void] ApplyCurrentViewFilter() {
        
    
        $dv = New-Object System.Data.DataView($this.dt)

        $dv.RowFilter = $this.viewFilter

        $this.currView = $dv
        $this.dataGrid.DataSource = $this.currView
    }

    [void] ResetViewFilter() {
        $this.viewFilter = ""
    }

    [void] SetRowUpdate([ScriptBlock] $script) {
        $this.rowUpdate = $script
    }

    [void] onRowUpdate([DataGridViewCellEventArgs] $e ) {
        
        if ($this.rowUpdate -eq $null) {
            return
        }
        
        $this.rowUpdate.Invoke($e, $this.dataGrid)

    }

    [void] onMouseRightClick([DataGridViewCellMouseEventArgs] $e) {
        if ($e.Button -eq [System.Windows.Forms.UserControl]::MouseButtons::Right) {

            $global:mainWindow = $this
            $grid = $this.dataGrid

            $global:cellName = $grid.Columns[$e.ColumnIndex].Name
            $cell = $grid.GetCellDisplayRectangle($e.ColumnIndex, $e.RowIndex, $true)

            $x = $cell.Left + $e.Location.X + 10
            $y = $cell.Top + $e.Location.Y + 5

            $cMenu = New-Object System.Windows.Forms.ContextMenu
            $filterItem = New-Object System.Windows.Forms.MenuItem("&Filter")

            $removeFilterItem = New-Object System.Windows.Forms.MenuItem("&Remove Filter")

            $cMenu.MenuItems.AddRange(@($filterItem, $removeFilterItem))
            $menuLocation = New-Object System.Drawing.Point($x, $y)

            
            $filterItem.Add_Click({
                        
                        
                    $filterWindow = [FilterWindow]::new("Filter Results: $global:cellName", $global:cellName)

                    $filterWindow.deploy($global:mainWindow)

                    $global:mainWindow.ApplyCurrentViewFilter()
                })

            $removeFilterItem.Add_Click({
                    $global:mainWindow.ResetViewFilter()

                    $global:mainWindow.ApplyCurrentViewFilter()
                })
            
            $cMenu.Show($grid, $menuLocation)
            

        
        }
    }

    [void] SetDataTable() {

        $Connection = New-Object System.Data.SQLClient.SQLConnection  
        $Connection.ConnectionString = $this.conn
        $Connection.Open()  
        $command = new-object system.data.sqlclient.sqlcommand($this.query, $connection)

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $command
        $data = New-Object System.Data.DataTable

        
        $SqlAdapter.Fill($data)

        $this.dt = $data

        $Connection.close()
    }

    [void] SetDataGrid() {
    
        $dataGridView = New-Object System.Windows.Forms.DataGridView
        $dvMain = New-Object System.Data.DataView($this.dt)
        $width = $this.size.Width - 15
        $height = $this.size.Height - 40

        $this.currView = $dvMain
        $dataGridView.Size = New-Object System.Drawing.Size($width, $height)

        $datagridView.DataSource = $dvMain
         
        $this.dataGrid = $dataGridView

        $this.dataGrid.HorizontalScrollingOffset = $false
       
    }

    [void] FilterPopUp([DataGridViewCellMouseEventArgs] $e) {

        if ($this.currView.Count -gt 100001) {
        
            [MessageBox]::Show("Too many rows to filter buckaroo!" , "Message" )
            return
        }
             
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y


        $filterForm = New-Object system.Windows.Forms.Form
        $filterForm.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
        $filterForm.Location = New-Object System.Drawing.Point($x, $y)
        $filterForm.minimumSize = New-Object System.Drawing.Size(200, 300)
        $filterForm.maximumSize = New-Object System.Drawing.Size(200, 900)

        $colName = $this.dataGrid.Columns[$e.ColumnIndex].Name

        $okButton = New-Object system.windows.Forms.Button
        $okButton.Text = "Ok"
        $okButton.Width = 50
        $okButton.Height = 30
        $queryWindow = $this
        $okButton.Add_Click({ 
                $queryWindow.ApplyFilterGridView($colName)
                $filterform.Dispose()

            })
        $okButton.location = new-object system.drawing.point(0, 265)
        $okButton.Font = "Microsoft Sans Serif,10"

        $cancelButton = New-Object system.windows.Forms.Button
        $cancelButton.Text = "Cancel"
        $cancelButton.Width = 80
        $cancelButton.Height = 30
        $cancelButton.Add_Click({ 
                $filterform.Dispose()
            })
        $cancelButton.location = new-object system.drawing.point(100, 265)
        $cancelButton.Font = "Microsoft Sans Serif,10"

        

        $data = @()

        foreach ($row in $this.currView.ToTable()) { 
            $items = $row.ItemArray
            $data += $items[$e.ColumnIndex]
 
            
        }

        $data = $data | Select -Unique

        $fGrid = New-Object System.Windows.Forms.DataGridView

        $fGrid.ColumnCount = 0
        $checkBoxCol = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn

        $filterCol = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $filterCol.Name = $this.dataGrid.Columns[$e.ColumnIndex].Name
        $dataTable = New-Object System.Windows.Forms.DataGridView
        
       
        $dataTable.Columns.Add($checkBoxCol)
        $dataTable.Columns.Add($filterCol)
        $dataTable.RowCount = $data.length
          
        $i = 0
        foreach ($item in $data) {

           
            $dataTable.Rows[$i].Cells[0].Value = $false
            $dataTable.Rows[$i].Cells[1].Value = $item
            $i += 1
        }




        $fGrid = $dataTable



  
        $fGrid.Size = New-Object System.Drawing.Size(200, 250)

        $fGrid.MaximumSize = New-Object System.Drawing.Size(200, 850)

                          
        $fGrid.AllowUserToAddRows = $false
        $fGrid.AllowUserToDeleteRows = $false
        $fGrid.RowHeadersVisible = $false
        $this.filterGrid = $fGrid

        $filterForm.Controls.Add($this.filterGrid)
        $filterForm.Controls.Add($okButton)

        $filterForm.Controls.Add($cancelButton)

        $filterForm.FormBorderStyle = [FormBorderStyle]::None

        $filterform.ShowDialog()

        
    }
    
    [void] ApplyFilterGridView([string]$colName) {
        
    
        $filterCount = 0
        $dataFilters = @()

        foreach ($row in $this.filterGrid.Rows) {
        
            if ($row.Cells[0].Value -eq $true) {
                
                $dataFilters += $row.Cells[1].Value
                $filterCount += 1
            }
        }

        $dataFilters = $dataFilters -join ("','")
        
        if ($filterCount -gt 0) {

            if ($this.viewFilter -ne "") {

                $this.viewFilter = -join ($this.viewFilter, " AND ", "$colName In ('$dataFilters')")
                $this.currView.RowFilter = $this.viewFilter
            }
            else {
                
                $this.viewFilter = "$colName In ('$dataFilters')"
                $this.currView.RowFilter = $this.viewFilter
            
            }
        }
        else {
        
            $this.viewFilter = ""
            $this.currView.RowFilter = $this.viewFilter
            
        }

        $this.dataGrid.DataSource = $this.currView
    }

    [void] Display() {
    

        $Form = New-Object system.Windows.Forms.Form
        $Form.Text = $this.name
        $Form.Size = $this.size

        $this.SetDataTable()
        $this.SetDataGrid()

        $queryWindow = $this
        
        $Form.add_ResizeEnd({

                $width = $Form.size.Width - 15
                $height = $Form.size.Height - 40
                $queryWindow.size = New-Object System.Drawing.Size($width, $height)
                $queryWindow.dataGrid.Size = $queryWindow.size

            })

        $this.dataGrid.add_CellMouseClick({ $queryWindow.onMouseRightClick($_) })
        $this.dataGrid.add_CellValueChanged({ $queryWindow.onRowUpdate($_) } )
        $this.dataGrid.add_ColumnHeaderMouseDoubleClick({ $queryWindow.FilterPopUp($_) } )
  
        foreach ($col in $this.dataGrid.Columns) {
            $col.AutoSizeMode = [DataGridViewAutoSizeColumnMode]::AllCells
    
        }
        $Form.Controls.Add($this.dataGrid)


        $this.window = $Form
        $this.window.ShowDialog()
        $this.window.Dispose()

    }



}


class FilterWindow {
    [System.Windows.Forms.Form] $window;    
    [string] $name;
    [string] $field;
    [string] $operator;
    [string] $value;
    [string] $filter;
    
    FilterWindow([string] $name, [string] $field) {

        $this.name = $name;
        $this.field = $field;

    }


    [void] deploy([QueryWindow] $window) {
        $form = New-Object System.Windows.Forms.Form
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y
        $col = $this.field

        $form.Location = New-Object System.Drawing.Point($x, $y)
        $form.Text = $this.name

        $form.MinimumSize = New-Object System.Drawing.Size(300, 160)
        $form.MaximumSize = New-Object System.Drawing.Size(300, 160)

        $form.MinimizeBox = $false
        $form.MaximizeBox = $false


        $operatorsLabel = New-Object System.Windows.Forms.Label

        $operatorsLabel.Text = "&Operator:" 
        $operatorsLabel.Font = "Microsoft Sans Serif,10"
        $operatorsLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

        $operatorsLabel.Width = 75
        $operatorsLabel.Location = New-Object System.Drawing.Point(15, 15)

        $operators = New-Object System.Windows.Forms.ComboBox
 
        $operators.Font = "Microsoft Sans Serif,8"

        $operators.Location = New-Object System.Drawing.Point(90, 15)
        $operators.Width = 150

        $operators.Items.Add("Starts With")
        $operators.Items.Add("Contains")
        $operators.Items.Add("Does Not Contain")
        $operators.Items.Add("Ends With")
        $operators.Items.Add("Equals")

        $operators.SelectedItem = "Equals"

        $operators.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList




        $valueLabel = New-Object System.Windows.Forms.Label
        $valueLabel.Text = "&Value:" 
        $valueLabel.Font = "Microsoft Sans Serif,10"
        $valueLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

        $valueLabel.Width = 75
        $valueLabel.Location = New-Object System.Drawing.Point(15, 50)


        $inputValue = New-Object System.Windows.Forms.TextBox

        $inputValue.Width = 150
        $inputValue.Location = New-Object System.Drawing.Point(90, 50)


        $inputValue.Add_TextChanged({
                if ($inputValue.TextLength -ge 1 ) {
                    $okButton.Enabled = $true
                }
    
            })

   
        $okButton = New-Object system.windows.Forms.Button
        $okButton.Text = "Ok"
        $okButton.Width = 70
        $okButton.Height = 20
        $okButton.Add_Click({ 
        
        
                $value = $inputValue.Text
                $query = ""

                if ($value -eq "") {
                    $form.Dispose()

                }

                Switch ($operators.SelectedItem) {
                    "Starts With" { $query = "$col LIKE '$value*'" }
                    "Contains" { $query = "$col LIKE '*$value*'" }
                    "Does Not Contain" { $query = "$col NOT LIKE '*$value*'" }
                    "Ends With" { $query = "$col LIKE '*$value'" }
                    "Equals" { $query = "$col = '$value'" }
                }
        
                $form.Dispose()

        
                $window.SetViewFilter($query)
                return



            })
        $okButton.location = new-object system.drawing.point(90, 90)

        $okButton.Font = "Microsoft Sans Serif,8"
        $okButton.Enabled = $false
    
        $cancelButton = New-Object system.windows.Forms.Button
        $cancelButton.Text = "Cancel"
        $cancelButton.Width = 70
        $cancelButton.Height = 20
        $cancelButton.Add_Click({ 
                $form.Dispose()
                return ""
            })
        $cancelButton.location = new-object system.drawing.point(170, 90)
        $cancelButton.Font = "Microsoft Sans Serif,8"



    
        $form.Controls.Add($operatorsLabel)
        $form.Controls.Add($operators)
        $form.Controls.Add($valueLabel)
        $form.Controls.Add($inputValue)

        $form.Controls.Add($okButton)
        $form.Controls.Add($cancelButton)

        $form.ShowDialog()
        $form.Dispose()

    }
       
}

