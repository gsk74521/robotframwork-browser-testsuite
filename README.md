# robotframwork-browser-testsuite

Robot Framework Browser（Playwright）+ Allure 的端到端测试套件仓库，
供 Jenkins job `robot-browser-demo`（http://124.220.193.176:8765/jenkins/）在**每次构建时拉取最新用例**执行。

## 目录结构

```
.
├── suites/                     # 一个子目录 = 一个可勾选的测试套件
│   ├── demo/                   # 端到端演示（登录 + 待办），端口 8899
│   ├── login/                  # 登录功能用例集（7 条），端口 8898
│   ├── todo/                   # 待办事项用例集（5 条），端口 8897
│   └── smoke/                  # 冒烟：不依赖浏览器，只校验环境与站点资源，端口 8896
├── suites.properties           # Jenkins 勾选参数 TEST_SUITES 的数据源
├── update-suites-properties.sh # 根据 suites/ 目录刷新上面的文件
└── README.md
```

## 新增一个测试套件

1. 在 `suites/` 下新建目录，例如 `suites/api/`，放入 `.robot` 文件；
   如用例依赖本地静态站点，站点目录要与 `.robot` 同级（用例里用 `${CURDIR}/site` 引用）。
2. 刷新勾选项数据文件：

   ```bash
   ./update-suites-properties.sh
   ```

   `--check` 参数只校验不写入（CI 里用来提示 suites.properties 过期）。
3. 提交并推送：

   ```bash
   git add -A && git commit -m "add suite: api" && git push
   ```
4. 下一次 Jenkins 构建时会自动拉取，构建页面即可勾选新套件。

## Jenkins 侧的对应关系

| Jenkins | 仓库 |
|---|---|
| 工作副本 `/opt/robot-suite/tests` | 本仓库（每次构建 `git fetch + reset --hard`，始终与 main 一致） |
| 参数 `TEST_SUITES`（多选框） | 读取本仓库的 `suites.properties`；勾 `all` 等于全部套件 |
| 构建脚本 | 把勾选项映射为 `suites/<名称>` 传给 `robot` |

注意：勾选框列表来自**上一次构建拉取后**的 `suites.properties`，所以新增套件后要提交该文件（由 `update-suites-properties.sh` 生成），勾选项才会在下次构建出现。

## 本地手动执行

```bash
cd <仓库目录>
export PATH=/opt/robot-suite/venv/bin:$PATH          # 或本地 venv
export PLAYWRIGHT_BROWSERS_PATH=/opt/robot-suite/pw-browsers
robot --listener allure_robotframework:allure-results --outputdir results suites/demo
allure generate allure-results -o allure-report --clean
```
