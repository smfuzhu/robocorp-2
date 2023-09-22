*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Minimal task
#    Log    Done.
    Get orders
    Open web
    Open csv
#    post data
    [Teardown]    create zip and KILL


*** Keywords ***
Get orders
    Download    url=https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Open csv
    ${table}=    Read table from CSV    orders.csv
    Log    Found columns: ${table.columns}
    FOR    ${row}    IN    @{table}
#    Log    ${row}[Head]
#    Log    ${row}[Address]
        post data    ${row}
    END

Open web
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    ${ISDIR}=    Does Directory Exist    ${OUTPUT_DIR}${/}pdf/
    IF    ${ISDIR} == ${False}    Create Directory    ${OUTPUT_DIR}${/}pdf/
    Set Selenium Speed    0.05

post data bak
#    [Arguments]    ${row}
#    Wait Until Page Contains Element    Xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait And Click Button    Xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    # 点击确定
    Select From List By Index    head    1
    Click Button    id-body-1
    Input Text    Xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    1
    Input Text    address    hello world
    Click Button    Order

    ${err}=    Is Element Visible    Xpath:/html/body/div/div/div[1]/div/div[1]/div
    WHILE    ${err} == $True    limit=NONE
        Click Button    Order
        ${err}=    Is Element Visible    Xpath:/html/body/div/div/div[1]/div/div[1]/div
    END

    Wait Until Page Contains Element    //*[@id="robot-preview-image"]/img[3]
    RPA.Browser.Selenium.Screenshot    //*[@id="root"]/div/div[1]    ${OUTPUT_DIR}${/}1.png
    ${files}=    Create List    ${OUTPUT_DIR}${/}1.png
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}1.pdf
    Click Button    Order another robot

post data
    [Arguments]    ${row}
#    Wait Until Page Contains Element    Xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait And Click Button    Xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    # OK
    Select From List By Index    head    ${row}[Head]
    Click Button    id-body-${row}[Body]
    Input Text    Xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    Order
    ${time}=    Set Selenium Speed    1
    Log    time1:${time}
    ${err}=    Is Element Visible    order-another
    Log    ${err}
    WHILE    ${err} == $False    limit=NONE
        Click Button    Order
        ${err}=    Is Element Visible    order-another
    END

    Wait Until Page Contains Element    //*[@id="robot-preview-image"]/img[3]
    RPA.Browser.Selenium.Screenshot    //*[@id="root"]/div/div[1]    ${TEMPDIR}${/}${row}[Order number].png
    ${files}=    Create List    ${TEMPDIR}${/}${row}[Order number].png
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}pdf${/}${row}[Order number].pdf
    Click Button    Order another robot
    ${time}=    Set Selenium Speed    ${time}
    Log    time2:${time}

create zip and KILL
    Archive Folder With Zip    folder=${OUTPUT_DIR}${/}pdf${/}    archive_name=${OUTPUT_DIR}${/}pdf.zip
    Close Browser
