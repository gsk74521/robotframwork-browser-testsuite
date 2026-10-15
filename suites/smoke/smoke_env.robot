*** Settings ***
Documentation     冒烟套件：不依赖浏览器，只校验测试环境与静态站点资源，执行很快，适合每次构建都跑。
Library           Process
Library           OperatingSystem
Library           String
Library           Collections

Suite Setup       Start Static Site
Suite Teardown    Stop Static Site

*** Variables ***
${SITE_DIR}       ${CURDIR}/site
${SITE_PORT}      8896
${BASE_URL}       http://127.0.0.1:${SITE_PORT}/index.html

*** Test Cases ***
静态站点首页可访问且包含标题
    [Tags]    smoke    fast
    ${result} =    Run Process    curl    -sS    --max-time    5    ${BASE_URL}
    Should Be Equal As Integers    ${result.rc}    0
    Should Contain    ${result.stdout}    Robot Framework Browser 演示站点

测试环境基础命令可用
    [Tags]    smoke    fast
    ${py} =    Run Process    python3    --version
    Should Be Equal As Integers    ${py.rc}    0
    ${curl} =    Run Process    curl    --version
    Should Be Equal As Integers    ${curl.rc}    0

字符串与列表处理符合预期
    [Tags]    smoke    fast
    ${upper} =    Convert To Upper Case    robot framework
    Should Be Equal    ${upper}    ROBOT FRAMEWORK
    ${text} =    Replace String    hello world    world    robot
    Should Be Equal    ${text}    hello robot
    @{items} =    Create List    alpha    beta    gamma
    Length Should Be    ${items}    3
    List Should Contain Value    ${items}    beta

*** Keywords ***
Start Static Site
    [Documentation]    拉起本地静态站点，并等待其可访问。
    ${handle} =    Start Process    python3    -m    http.server    ${SITE_PORT}
    ...    --bind    127.0.0.1    --directory    ${SITE_DIR}    alias=smoke-site
    Set Global Variable    ${SITE_HANDLE}    ${handle}
    Wait Until Keyword Succeeds    20x    0.5s    Site Is Reachable

Site Is Reachable
    [Documentation]    用 curl 退出码判断服务是否就绪（不依赖浏览器）。
    ...                注意：不能写 curl 的 -w '%{http_code}'，Robot 会把 %{...} 解析成环境变量。
    ${result} =    Run Process    curl    -sS    -f    --max-time    5    -o    /dev/null    ${BASE_URL}
    Should Be Equal As Integers    ${result.rc}    0

Stop Static Site
    Terminate Process    ${SITE_HANDLE}    kill=True
