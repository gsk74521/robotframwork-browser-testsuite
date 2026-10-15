*** Settings ***
Documentation     演示 robotframework-browser（Playwright）端到端 Web 测试。
...               被测站点由 Suite Setup 启动的本地 HTTP 服务提供，保证 CI 中稳定、可重复。
...               配合 allure-robotframework 监听器可生成 Allure 报告。
...               注意：Browser 库只有 take_screenshot，没有 set_screenshot_directory（那是 SeleniumLibrary 的），
...               所以截图一律显式传完整路径。
Library           Browser
Library           Process
Library           OperatingSystem

Suite Setup       Start Local Test Site
Suite Teardown    Stop Local Test Site
Test Setup        Open Demo Site
Test Teardown     Run Keyword If Test Failed    Take Failure Screenshot

*** Variables ***
${SITE_DIR}       ${CURDIR}/site
${SITE_PORT}      8899
${BASE_URL}       http://127.0.0.1:${SITE_PORT}/index.html
${BROWSER}        chromium
${SHOT_DIR}       ${OUTPUT DIR}/screenshots

*** Test Cases ***
页面可以正常打开且标题正确
    [Tags]    smoke
    Get Title    ==    RF Browser Demo
    Get Text    h1    ==    Robot Framework Browser 演示站点

使用正确账号登录成功
    [Tags]    smoke    login
    Fill Text    css=#username    alice
    Fill Text    css=#password    s3cret
    Click    css=#login
    Get Text    css=#message    ==    欢迎, alice
    Take Screenshot    ${SHOT_DIR}/login-success.png

使用错误密码登录失败
    [Tags]    login    negative
    Fill Text    css=#username    alice
    Fill Text    css=#password    wrong-password
    Click    css=#login
    Get Text    css=#message    ==    用户名或密码错误
    Take Screenshot    ${SHOT_DIR}/login-failed.png

空表单提交被前端校验拦截
    [Tags]    login    negative
    Click    css=#login
    Get Text    css=#message    ==    用户名和密码不能为空

可以新增待办并勾选完成
    [Tags]    todo
    Fill Text    css=#todo-input    写一份 Robot 测试报告
    Click    css=#add-todo
    Fill Text    css=#todo-input    把结果发布到 Jenkins
    Click    css=#add-todo
    Get Text    css=#todo-count    ==    共 2 项，已完成 0 项
    Click    css=#todo-list li:nth-child(1) input[type=checkbox]
    Get Text    css=#todo-count    ==    共 2 项，已完成 1 项
    Get Text    css=#todo-list li:nth-child(1) span    ==    写一份 Robot 测试报告
    Take Screenshot    ${SHOT_DIR}/todo-list.png

*** Keywords ***
Start Local Test Site
    [Documentation]    拉起本地静态站点，并等待其可访问。
    ${handle} =    Start Process    python3    -m    http.server    ${SITE_PORT}
    ...    --bind    127.0.0.1    --directory    ${SITE_DIR}    alias=site
    Set Global Variable    ${SITE_HANDLE}    ${handle}
    Wait Until Keyword Succeeds    20x    0.5s    Site Is Reachable

Site Is Reachable
    [Documentation]    用 curl 退出码判断服务是否就绪（不依赖浏览器）。
    ...                注意：不能写 curl 的 -w '%{http_code}'，Robot 会把 %{...} 解析成环境变量。
    ${result} =    Run Process    curl    -sS    -f    --max-time    5    -o    /dev/null    ${BASE_URL}
    Should Be Equal As Integers    ${result.rc}    0

Open Demo Site
    New Browser    ${BROWSER}    headless=True
    Set Browser Timeout    15s
    New Page    ${BASE_URL}

Take Failure Screenshot
    [Documentation]    用例失败时截图取证；浏览器未打开时忽略错误，避免掩盖真实失败原因。
    Run Keyword And Ignore Error    Take Screenshot    ${SHOT_DIR}/failure-${TEST_NAME}.png

Stop Local Test Site
    Close Browser    ALL
    Terminate Process    ${SITE_HANDLE}    kill=True
