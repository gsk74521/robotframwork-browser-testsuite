*** Settings ***
Documentation     登录功能套件：账号密码校验相关用例的独立集合（Browser 库驱动本地演示站点）。
...               站点内置账号：alice/s3cret、bob/hunter2。
Library           Browser
Library           Process
Library           OperatingSystem

Suite Setup       Start Local Test Site
Suite Teardown    Stop Local Test Site
Test Setup        Open Demo Site
Test Teardown     Run Keyword If Test Failed    Take Failure Screenshot

*** Variables ***
${SITE_DIR}       ${CURDIR}/site
${SITE_PORT}      8898
${BASE_URL}       http://127.0.0.1:${SITE_PORT}/index.html
${BROWSER}        chromium
${SHOT_DIR}       ${OUTPUT DIR}/screenshots

*** Test Cases ***
alice 使用正确密码登录成功
    [Tags]    login    smoke
    Login With    alice    s3cret
    Get Text    css=#message    ==    欢迎, alice
    Take Screenshot    ${SHOT_DIR}/login-alice.png

bob 也能登录成功
    [Tags]    login
    Login With    bob    hunter2
    Get Text    css=#message    ==    欢迎, bob

密码大小写敏感
    [Tags]    login    negative
    Login With    alice    S3CRET
    Get Text    css=#message    ==    用户名或密码错误

用户名与密码必须成对匹配
    [Tags]    login    negative
    Login With    alice    hunter2
    Get Text    css=#message    ==    用户名或密码错误

用户名两侧空格被忽略
    [Tags]    login
    Fill Text    css=#username    ${SPACE}alice${SPACE}
    Fill Text    css=#password    s3cret
    Click    css=#login
    Get Text    css=#message    ==    欢迎, alice

只输用户名不输密码被前端校验拦截
    [Tags]    login    negative
    Fill Text    css=#username    alice
    Click    css=#login
    Get Text    css=#message    ==    用户名和密码不能为空

只输密码不输用户名被前端校验拦截
    [Tags]    login    negative
    Fill Text    css=#password    s3cret
    Click    css=#login
    Get Text    css=#message    ==    用户名和密码不能为空

*** Keywords ***
Start Local Test Site
    [Documentation]    拉起本地静态站点，并等待其可访问。
    ${handle} =    Start Process    python3    -m    http.server    ${SITE_PORT}
    ...    --bind    127.0.0.1    --directory    ${SITE_DIR}    alias=login-site
    Set Global Variable    ${SITE_HANDLE}    ${handle}
    Wait Until Keyword Succeeds    20x    0.5s    Site Is Reachable

Site Is Reachable
    ${result} =    Run Process    curl    -sS    -f    --max-time    5    -o    /dev/null    ${BASE_URL}
    Should Be Equal As Integers    ${result.rc}    0

Login With
    [Arguments]    ${user}    ${password}
    Fill Text    css=#username    ${user}
    Fill Text    css=#password    ${password}
    Click    css=#login

Open Demo Site
    New Browser    ${BROWSER}    headless=True
    Set Browser Timeout    15s
    New Page    ${BASE_URL}

Take Failure Screenshot
    Run Keyword And Ignore Error    Take Screenshot    ${SHOT_DIR}/failure-${TEST_NAME}.png

Stop Local Test Site
    Close Browser    ALL
    Terminate Process    ${SITE_HANDLE}    kill=True
