*** Settings ***
Documentation     待办事项套件：新增 / 勾选 / 计数 相关用例的独立集合（Browser 库驱动本地演示站点）。
Library           Browser
Library           Process
Library           OperatingSystem

Suite Setup       Start Local Test Site
Suite Teardown    Stop Local Test Site
Test Setup        Open Todo Site
Test Teardown     Run Keyword If Test Failed    Take Failure Screenshot

*** Variables ***
${SITE_DIR}       ${CURDIR}/site
${SITE_PORT}      8897
${BASE_URL}       http://127.0.0.1:${SITE_PORT}/index.html
${BROWSER}        chromium
${SHOT_DIR}       ${OUTPUT DIR}/screenshots
${TODO_COUNT}     css=#todo-count

*** Test Cases ***
新增两项待办后计数正确
    [Tags]    todo
    Add Todo    写测试用例
    Add Todo    提交到 Git
    Get Text    ${TODO_COUNT}    ==    共 2 项，已完成 0 项

勾选一项后计数与完成样式生效
    [Tags]    todo
    Add Todo    第一项
    Add Todo    第二项
    Check Todo    1
    Get Text    ${TODO_COUNT}    ==    共 2 项，已完成 1 项
    Get Attribute    css=#todo-list li:nth-child(1) span    class    ==    done
    Get Text    css=#todo-list li:nth-child(1) span    ==    第一项
    Take Screenshot    ${SHOT_DIR}/todo-partial.png

全部勾选后计数为全部完成
    [Tags]    todo
    Add Todo    A
    Add Todo    B
    Add Todo    C
    Check Todo    1
    Check Todo    2
    Check Todo    3
    Get Text    ${TODO_COUNT}    ==    共 3 项，已完成 3 项

取消勾选后计数回退
    [Tags]    todo
    Add Todo    可取消项
    Check Todo    1
    Get Text    ${TODO_COUNT}    ==    共 1 项，已完成 1 项
    Uncheck Todo    1
    Get Text    ${TODO_COUNT}    ==    共 1 项，已完成 0 项

空输入不会新增待办
    [Tags]    todo    negative
    Click    css=#add-todo
    Get Element Count    css=#todo-list li    ==    0
    Get Text    ${TODO_COUNT}    ==    共 0 项，已完成 0 项

*** Keywords ***
Start Local Test Site
    [Documentation]    拉起本地静态站点，并等待其可访问。
    ${handle} =    Start Process    python3    -m    http.server    ${SITE_PORT}
    ...    --bind    127.0.0.1    --directory    ${SITE_DIR}    alias=todo-site
    Set Global Variable    ${SITE_HANDLE}    ${handle}
    Wait Until Keyword Succeeds    20x    0.5s    Site Is Reachable

Site Is Reachable
    ${result} =    Run Process    curl    -sS    -f    --max-time    5    -o    /dev/null    ${BASE_URL}
    Should Be Equal As Integers    ${result.rc}    0

Add Todo
    [Arguments]    ${text}
    Fill Text    css=#todo-input    ${text}
    Click    css=#add-todo

Check Todo
    [Arguments]    ${index}
    Click    css=#todo-list li:nth-child(${index}) input[type=checkbox]

Uncheck Todo
    [Arguments]    ${index}
    Uncheck Checkbox    css=#todo-list li:nth-child(${index}) input[type=checkbox]

Open Todo Site
    New Browser    ${BROWSER}    headless=True
    Set Browser Timeout    15s
    New Page    ${BASE_URL}

Take Failure Screenshot
    Run Keyword And Ignore Error    Take Screenshot    ${SHOT_DIR}/failure-${TEST_NAME}.png

Stop Local Test Site
    Close Browser    ALL
    Terminate Process    ${SITE_HANDLE}    kill=True
