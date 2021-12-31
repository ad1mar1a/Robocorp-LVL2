*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@type="number"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    FOR    ${i}    IN RANGE    9999999
        ${alert}=    Is Element Visible    xpath://div[@class="alert alert-danger"]
        Exit For Loop If    ${alert} == False
        Click Button    order
    END

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${file_name}=    Catenate    SEPARATOR=-    receipt    ${order_number}    .pdf
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}${file_name}
    [Return]    ${OUTPUT_DIR}${/}${file_name}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    ${file_name}=    Catenate    SEPARATOR=-    robot_preview    ${order_number}.png
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${file_name}
    [Return]    ${OUTPUT_DIR}${/}${file_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${preview}    ${receipt}
    ${files}=    Create List
    ...    ${receipt}
    ...    ${preview}
    Add Files To Pdf    ${files}    ${receipt}
    Remove File    ${preview}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}receipts.zip    include=*.pdf

Close the browser
    Close Browser
