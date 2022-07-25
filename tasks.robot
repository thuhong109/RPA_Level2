*** Settings ***
Documentation   Order robots from RobotSparBin Industries Inc
...             Save the order HTML receipt as a PDF file    
...             Save the screenshot of order robot.
...             Embeds the screenshot of the robot to the PDF receipt
...             Creates Zip Archive of the receipts and images
Library         RPA.Browser.Selenium
Library         RPA.Tables                # Read table from CSV
Library         RPA.HTTP
Library         OperatingSystem
Library         String
Library         RPA.PDF                   # PDF functions 
Library         RPA.Archive               # Zip file
Library         RPA.Robocloud.Secrets
# Library         RPA.Dialogs
Library         Dialogs
Suite Setup     Open the robot website

*** Variables ***
${DOWNLOAD_DIR}     ${CURDIR}${/}Download
${URL}              https://robotsparebinindustries.com
${RSBInc}           xpath=//a[@class="nav-link"]                     #https://robotsparebinindustries.com/#/robot-order
${CSVFile}          https://robotsparebinindustries.com/orders.csv
${ButtonOK}         xpath=//div[@class="alert-buttons"]/button[@class="btn btn-dark"]
${Head}             xpath=//select[@id="head"] 
${Body}             body    
${RadBody}          id:id-body-
${Legs}             xpath=//div[@class="form-group"]/input[@placeholder="Enter the part number for the legs"]
${SAddress}         xpath=//div[@class="form-group"]/input[@placeholder="Shipping address"]  
${Review}           xpath=//button[@id="preview"]
${ReviewImage}      xpath=//div[@id="robot-preview-image"]
${Dialog}           xpath=//div[@class="modal-dialog"] 
${RobotReview}      xpath=//div[@id="robot-preview"]  
${Receipt}          xpath=//div[@id="receipt"]
${ButtonOrder}      xpath=//button[@id="order"]
${ButtonOAnother}   xpath=//button[@id="order-another"]
${RetryMount}=                  5x
${RetryInterval}=               0.5s
${FILENAME}=    orders.csv

*** Keywords ***
Open the robot website
    [Documentation]    Open Website and try to use Vault file.
    Open Available Browser          ${URL} 
    Set Selenium Implicit Wait      1       #wait page load completed
    ${secret}=    Get Secret    credentials
    Input Text            id:username    ${secret}[username]
    Input Password        id:password    ${secret}[password]
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Open the robot order website
    Click Element    xpath=//a[@class="nav-link"]
    Close the annoying modal


Get Order By CSV
    # [Documentation]    Download CSV file then read data from that file.
    # ...                Return a list item of CSV file without header.
    # Download            ${CSVFile}                  ${DOWNLOAD_DIR}        overwrite=True
    ${orders}=          Read table from CSV         ${CURDIR}${/}orders.csv
    # ${orders}=          Read table from CSV         ${DOWNLOAD_DIR}${/}orders.csv
    [Return]            ${orders}


Close the annoying modal
    [Documentation]    If the modal dialog is open then closed it.
    ${isDialogVisible}=       Run Keyword And Return Status     Element Should Be Visible   ${Dialog}      
    Run Keyword If            ${isDialogVisible}                Click Button                ${ButtonOK} 
Collect Search Query From User
    # Add heading        Input URL of order file
    # Add Text Input    search    label= Search query
    # Add Text    URL : "https://robotsparebinindustries.com/orders.csv"
    # ${response}=    Run dialog
    ${response} =	Get Value From User  Input URL to dowload
    [Return]    ${response}
    # ${response} =	Get Value From User	Input user name	default

Download Order file to Download Dir 
    ${urlOrder}=     Collect Search Query From User
    Set Download Directory        ${CURDIR}
    Download    ${urlOrder}    ${CURDIR}     overwrite=True
    Wait Until Keyword Succeeds    
    ...    2 min
    ...    5 sec
    ...    File Should Exist
    ...    ${FILENAME}
    
Fill the form    
    [Documentation]        Fill data to controls in form
    ...                    Format of the Row is: Head, Body, Legs, Address
    [Arguments]                  ${row}    
    Wait Until Element Is Visible               ${Head}      
    Select From List By Value    ${Head}        ${row}[Head]
    Click Element When Visible   ${RadBody}${row}[Body]
    Input Text                   ${Legs}        ${row}[Legs]
    Input Text                   ${SAddress}    ${row}[Address]

Preview the robot     
    Click Element When Visible        ${Review} 
    Wait Until Element Is Visible     ${RobotReview}


Submit the order
    Click Button            ${ButtonOrder} 

Submit The Order and Checking until Success
    [Documentation]    Submit order by click on button "Order"
    ...                Wait until key work success
    Wait Until Keyword Succeeds    
    ...    ${RetryMount}
    ...    ${RetryInterval}
    ...    Submit the order
    ${present}=       Run Keyword And Return Status    Element Should Be Visible   ${ButtonOrder} 
    Run Keyword If    ${present}    Submit The Order and Checking until Success

Get Receipt
    ${receipt_results_html}=        Get Element Attribute    ${Receipt}       outerHTML
    [Return]                        ${receipt_results_html}
Store the receipt as a PDF file
    [Documentation]  Store the PDF.
    ...              Check if the order already summit before store PDF. 
    ...              If the Order still not summitted then try again              

    [Arguments]      ${OrderNumber}
    ${present}=      Run Keyword And Return Status    Element Should Be Visible   ${ButtonOrder} 
    IF    ${present} == True
        Submit The Order and Checking until Success
        Store the receipt as a PDF file     ${OrderNumber}
    ELSE
        No Operation
    END
    ${receipthtml}=        Get Element Attribute      ${Receipt}       outerHTML
    Html To Pdf            ${receipthtml}             ${CURDIR}${/}output${/}receipt_${OrderNumber}.pdf  
    [Return]               ${CURDIR}${/}output${/}receipt_${OrderNumber}.pdf  

Take a screenshot of the robot
    [Documentation]     Take a sceenshot of Robot then store in Download directory.
    [Arguments]         ${OrderNumber}
    Screenshot          ${RobotReview}          ${DOWNLOAD_DIR}${/}Robot_${OrderNumber}.JPEG
    [Return]            ${DOWNLOAD_DIR}${/}Robot_${OrderNumber}.JPEG

     

Embed the robot screenshot to the receipt PDF file    
    [Documentation]       Open current PDF (strored at keyword: Store the receipt as a PDF file) 
    ...                   and add robot at (Take a screenshot of the robot) to PDF then save with diffence name.
    [Arguments]           ${pdf}        ${OrderNumber}
    ${receiptPDF}=        Open Pdf    ${pdf}
    ${files}=             Create List      ${pdf}        ${DOWNLOAD_DIR}${/}Robot_${OrderNumber}.JPEG 
    Add Files To Pdf      ${files}    ${CURDIR}${/}output${/}receipt${/}Robot_Order${OrderNumber}.pdf    
    Close Pdf             ${pdf}

 Go to order another robot
    Click Element When Visible        ${ButtonOAnother}     

Create a ZIP file of the receipts     
    [Documentation]    Add all receipt files to a zip found.
    Archive Folder With Zip     ${CURDIR}${/}output${/}receipt      ${CURDIR}${/}output${/}receipts.zip   recursive=True  include=*.pdf  
    Remove Directory            ${CURDIR}${/}output${/}receipt      recursive=True 

Process order
    [Documentation]        Close dialog then fill data in to the form, review the robot then submit the order.
    ...                    Save the screenshot of order robot.
    ...                    Embeds the screenshot of the robot to the PDF receipt
    ...                    Finally go to the next order.    
    
    [Arguments]     ${order}
    Close the annoying modal
    Fill the form     ${order}
    Preview the robot
    Wait Until Keyword Succeeds    ${RetryMount}     ${RetryInterval}     Submit the order
    ${pdf}=    Store the receipt as a PDF file       ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot     ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${pdf}     ${order}[Order number]
    Go to order another robot

*** Tasks ***
Order robots form RobotSpareBin Industries Inc
    Create Directory    ${DOWNLOAD_DIR}
    Set Download Directory     ${DOWNLOAD_DIR}
    Create Directory           ${CURDIR}${/}output${/}receipt
    # Collect Search Query From User
    Download Order file to Download Dir
    Open the robot order website
    ${orders}=    Get Order By CSV
   
    FOR    ${row}   IN      @{orders}
        Run Keyword And Continue On Failure    Process order    ${row}
    END
    Create a ZIP file of the receipts
    Remove Directory        ${DOWNLOAD_DIR}    recursive=True 


