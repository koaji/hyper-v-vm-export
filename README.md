# hyper-v-vm-export

## 概要
  定義ファイルに記載したVMを指定ディレクトリへエクスポートするスクリプト。
  1世代バックアップに対応する。

## 使い方
`./hyperv_vm_export.ps1 LOG_FILE_PATH DEFINE_FILE_PATH`

  LOG_FILE_PATH    : ログファイルを格納するパスを指定する。
                     ファイル名はHyperV_VM_BackupLog_[yyyyMMdd_hhmmss].log
  DEFINE_FILE_PATH : 定義ファイルへのフルパスを指定する。
                     第1カラム目は対象VM名、第2カラム目は格納先ディレクトリ。

## 活用例
### 定期実行
  Windows標準機能のタスクスケジューラを用いて、定期的に実行できる。
  サンプルの定義ファイルは sample/task_scheduler フォルダの定義を参照のこと。

