#!/bin/bash
# 扫描 suites/ 下的套件目录，生成（或校验）Jenkins 勾选参数的数据文件 suites.properties
# 用法：
#   ./update-suites-properties.sh          写入 suites.properties
#   ./update-suites-properties.sh --check  只校验，不一致时退出码 1（CI 用来提示文件过期）
cd "$(dirname "$0")" || exit 1

SUITES=$(ls -d suites/*/ 2>/dev/null | sed 's#/$##' | sed 's#^suites/##' | paste -sd, -)
NEW="TEST_SUITES=all${SUITES:+,$SUITES}"

if [ "$1" = "--check" ]; then
  CUR=$(cat suites.properties 2>/dev/null)
  if [ "$CUR" = "$NEW" ]; then
    echo "[ok] suites.properties 与实际目录一致: $NEW"
    exit 0
  fi
  echo "[warn] suites.properties 与实际目录不一致（新增套件后请执行 ./update-suites-properties.sh 并提交）"
  echo "       当前: $CUR"
  echo "       应为: $NEW"
  exit 1
fi

echo "$NEW" > suites.properties
echo "已更新 suites.properties: $NEW"
